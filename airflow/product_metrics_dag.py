import json
import logging
import os

from datetime import datetime, timedelta, timezone
from pathlib import Path

from airflow.sdk import DAG
from airflow.providers.standard.operators.bash import BashOperator


PROJECT_ID = "sixth-tempo-506411-d9"

# Корень локального Git-репозитория:
# ~/projects/floodit-product-analytics
PROJECT_ROOT = Path(__file__).resolve().parents[1]

# Рабочая директория внутри Google Cloud Shell
REMOTE_ROOT = "/home/g1234567kazakova/floodit-airflow"


def task_failure_alert(context):
    """Записывает информацию о финальном падении Airflow task."""

    ti = context.get("task_instance") or context.get("ti")

    alert = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "dag_id": getattr(ti, "dag_id", None),
        "task_id": getattr(ti, "task_id", None),
        "run_id": (
            context.get("run_id")
            or getattr(ti, "run_id", None)
        ),
        "try_number": getattr(ti, "try_number", None),
        "exception": str(context.get("exception")),
    }

    logger = logging.getLogger("airflow.failure_alert")

    payload = json.dumps(
        alert,
        ensure_ascii=False,
    )

    # Записываем alert в Airflow logs
    logger.error(
        "AIRFLOW_FAILURE_ALERT: %s",
        payload,
    )

    # И отдельно сохраняем историю failure alerts
    alert_file = Path(
        os.getenv(
            "AIRFLOW_HOME",
            Path.home() / "airflow",
        )
    ) / "failure_alerts.jsonl"

    try:
        alert_file.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        with alert_file.open(
            "a",
            encoding="utf-8",
        ) as file:
            file.write(payload + "\n")

    except Exception:
        logger.exception(
            "Failed to write failure alert to %s",
            alert_file,
        )


def bq(
    task_id: str,
    sql_file: str,
) -> BashOperator:
    """
    Выполняет SQL-файл в BigQuery через Google Cloud Shell
    и корректно передаёт ошибку выполнения в Airflow.
    """

    remote_sql_file = (
        f"{REMOTE_ROOT}/{sql_file}"
    )

    return BashOperator(
        task_id=task_id,
        bash_command=f"""
set -euo pipefail

output=$(
    gcloud cloud-shell ssh \
        --authorize-session \
        --quiet \
        --command='
            bq query \
                --project_id={PROJECT_ID} \
                --use_legacy_sql=false \
                < {remote_sql_file} 2>&1

            status=$?
            echo "__BQ_EXIT_CODE__=$status"
        '
)

printf '%s\\n' "$output"

if ! printf '%s\\n' "$output" | grep -q "__BQ_EXIT_CODE__=0"; then
    echo "BigQuery query failed" >&2
    exit 1
fi
""",
    )

def product_alert(
    task_id: str,
    sql_file: str,
) -> BashOperator:
    """
    Проверяет последние продуктовые метрики.

    При наличии аномалий пишет предупреждение в Airflow logs
    и сохраняет его в product_alerts.log.
    Аномалия не приводит к падению pipeline.
    """

    remote_sql_file = f"{REMOTE_ROOT}/{sql_file}"

    return BashOperator(
        task_id=task_id,
        bash_command=f"""
set -euo pipefail

output=$(
    gcloud cloud-shell ssh \
        --authorize-session \
        --quiet \
        --command='
            bq query \
                --project_id={PROJECT_ID} \
                --use_legacy_sql=false \
                --format=csv \
                --quiet \
                < {remote_sql_file} 2>&1

            status=$?
            echo "__BQ_EXIT_CODE__=$status"
        '
)

printf '%s\\n' "$output"

# Если не выполнился сам SQL — это уже техническая ошибка.
if ! printf '%s\\n' "$output" | grep -q "__BQ_EXIT_CODE__=0"; then
    echo "Product monitoring query failed" >&2
    exit 1
fi

alerts=$(
    printf '%s\\n' "$output" \
        | grep '^PRODUCT_ANOMALY_ALERT|' \
        || true
)

if [ -n "$alerts" ]; then

    while IFS= read -r alert; do

        echo "PRODUCT_ANOMALY_ALERT: $alert" >&2

        printf '%s %s\\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            "$alert" \
            >> "$AIRFLOW_HOME/product_alerts.log"

    done <<< "$alerts"

else
    echo "No product anomalies detected for latest metric date."
fi
""",
    )


with DAG(
    dag_id="floodit_product_metrics",
    start_date=datetime(
        2026,
        9,
        1,
        tzinfo=timezone.utc,
    ),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    default_args={
        "owner": "analytics",
        "retries": 1,
        "retry_delay": timedelta(minutes=2),
        "on_failure_callback": task_failure_alert,
    },
    tags=[
        "floodit",
        "product-analytics",
        "bigquery",
    ],
) as dag:

    # 1. Синхронизация SQL и tests с Google Cloud Shell

    sync = BashOperator(
        task_id="sync_sql_to_cloud_shell",
        bash_command=f"""
set -euo pipefail

gcloud cloud-shell ssh \
    --authorize-session \
    --quiet \
    --command='rm -rf {REMOTE_ROOT} && mkdir -p {REMOTE_ROOT}'

gcloud cloud-shell scp \
    --recurse \
    --quiet \
    "localhost:{PROJECT_ROOT}/sql" \
    "cloudshell:{REMOTE_ROOT}/"

gcloud cloud-shell scp \
    --recurse \
    --quiet \
    "localhost:{PROJECT_ROOT}/tests" \
    "cloudshell:{REMOTE_ROOT}/"
""",
    )

    # 2. Основной analytical pipeline

    pipeline = [
        (
            "check_raw_data",
            "tests/check_raw_data.sql",
        ),
        (
            "build_stg_events",
            "sql/staging/stg_events.sql",
        ),
        (
            "build_users",
            "sql/intermediate/users.sql",
        ),
        (
            "build_sessions",
            "sql/intermediate/sessions.sql",
        ),
        (
            "build_events",
            "sql/intermediate/events.sql",
        ),
        (
            "build_gameplay_attempts",
            "sql/intermediate/gameplay_attempts.sql",
        ),
        (
            "build_user_early_journey",
            "sql/marts/mart_user_early_journey.sql",
        ),
        (
            "check_user_mart",
            "tests/data_quality.sql",
        ),
    ]

    tasks = [
        sync,
        *[
            bq(task_id, sql_file)
            for task_id, sql_file in pipeline
        ],
    ]

    for current_task, next_task in zip(
        tasks,
        tasks[1:],
    ):
        current_task >> next_task

    # 3. Dashboard marts

    dashboards = [
        bq(
            f"build_dashboard_{name}",
            f"sql/marts/mart_dashboard_{name}.sql",
        )
        for name in (
            "overview",
            "early_journey",
            "retention",
        )
    ]

    # 4. Проверка согласованности dashboard marts

    check_dashboard = bq(
        "check_dashboard_consistency",
        "tests/dashboard_consistency.sql",
    )

    # 5. Product monitoring

    build_product_monitoring = bq(
        "build_product_monitoring",
        "sql/monitoring/mart_product_monitoring.sql",
    )

    check_product_anomalies = product_alert(
    "check_product_anomalies",
    "sql/monitoring/check_product_anomalies.sql",
    )

    # Dependencies

    tasks[-1] >> dashboards

    dashboards >> check_dashboard

    check_dashboard >> build_product_monitoring >> check_product_anomalies