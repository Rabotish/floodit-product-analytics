# Flood-It Product Analytics Pipeline

Airflow-пайплайн для построения аналитических витрин Flood-It!, проверки качества данных и автоматического мониторинга ключевых продуктовых метрик.

Пайплайн обрабатывает данные Firebase / GA4 в BigQuery, последовательно строит staging-, intermediate- и mart-слои, выполняет data quality checks, обновляет витрины для Looker Studio и запускает мониторинг продуктовых метрик.

## Архитектура

```text
Firebase / GA4 public dataset
          │
          ▼
      BigQuery raw
          │
          ▼
     stg_events
          │
          ▼
 ┌──────────────────┐
 │ intermediate     │
 │                  │
 │ users            │
 │ sessions         │
 │ events           │
 │ gameplay_attempts│
 └────────┬─────────┘
          │
          ▼
mart_user_early_journey
          │
          ▼
    Data Quality
          │
          ▼
 ┌───────────────────────────┐
 │ Dashboard marts           │
 │                           │
 │ overview                  │
 │ early_journey             │
 │ retention                 │
 └─────────────┬─────────────┘
               │
               ▼
 dashboard_consistency
               │
               ▼
 mart_product_monitoring
               │
               ▼
 check_product_anomalies
```

Из-за ограничения локального доступа к BigQuery API SQL-запросы выполняются через Google Cloud Shell:

```text
Local Airflow
     │
     ▼
gcloud cloud-shell ssh
     │
     ▼
Google Cloud Shell
     │
     ▼
bq query
     │
     ▼
BigQuery
```

Перед каждым запуском Airflow синхронизирует актуальные каталоги sql/ и tests/ из локального Git-репозитория в рабочую директорию Cloud Shell.

## Требования

- Python 3.12
- Apache Airflow 3.3.x
- Google Cloud CLI
- BigQuery CLI (bq)
- доступ к Google Cloud Shell
- Google Cloud project с BigQuery
- Git

В проекте Airflow запускается в отдельном виртуальном окружении, чтобы избежать конфликтов зависимостей.: `.venv-airflow`

## Структура

```text

airflow/
└── product_metrics_dag.py

sql/
├── staging/
│   └── stg_events.sql
│
├── intermediate/
│   ├── users.sql
│   ├── sessions.sql
│   ├── events.sql
│   └── gameplay_attempts.sql
│
├── marts/
│   ├── mart_user_early_journey.sql
│   ├── mart_dashboard_overview.sql
│   ├── mart_dashboard_early_journey.sql
│   └── mart_dashboard_retention.sql
│
└── monitoring/
    ├── mart_product_monitoring.sql
    └── check_product_anomalies.sql

tests/
├── check_raw_data.sql
├── data_quality.sql
└── dashboard_consistency.sql

docs/
└── monitoring.md

```
## DAG

DAG: floodit_product_metrics

Запуск выполняется вручную: schedule=None

Обусловлено тем, что используемый датасет не обновляется и является историческим, при необходимости в продакшене pipeline может быть переведён на ежедневное расписание.

## Pipeline

``` text
    sync_sql_to_cloud_shell
            ↓
    check_raw_data
            ↓
    build_stg_events
            ↓
    build_users
            ↓
    build_sessions
            ↓
    build_events
            ↓
    build_gameplay_attempts
            ↓
    build_user_early_journey
            ↓
    check_user_mart
            ↓
    ┌────────────────────────────────┐
    ↓                ↓               ↓
    build_dashboard_  build_dashboard_  build_dashboard_
    overview          early_journey     retention
    └────────────────┬───────────────┘
                    ↓
    check_dashboard_consistency
                    ↓
    build_product_monitoring
                    ↓
    check_product_anomalies

```

## Запуск

### Клонирование

```code
git clone <repository-url>
cd floodit-product-analytics
```
### Активация Airflow environment

``` code
source .venv-airflow/bin/activate
```
### Настройка Airflow

``` code
export FLOODIT_PROJECT_ID="your-project-id"

export FLOODIT_REMOTE_ROOT="/home/<cloud-shell-user>/floodit-airflow"
```

### Авторизация Google Cloud

```code
gcloud auth login
gcloud config get-value project
```

### Проверка Cloud Shell

```code
gcloud cloud-shell ssh \
  --authorize-session \
  --command='echo $HOME'

gcloud cloud-shell ssh \
  --authorize-session \
  --command='bq query \
    --project_id=sixth-tempo-506411-d9 \
    --use_legacy_sql=false \
    "SELECT 1 AS test"'

```

### Проверка DAG

```code
python -m py_compile airflow/product_metrics_dag.py

airflow dags list-import-errors

airflow dags reserialize

```

### Запуск Airflow

```code
airflow standalone

```
http://localhost:8080

## Data Quality

tests/check_raw_data.sql - проверяет доступность исходных Firebase-таблиц.

tests/data_quality.sql - проверяет:

- наличие данных;
- уникальность пользователя;
- отсутствие обязательных NULL;
- согласованность timestamps и outcomes;
- корректность activation flags;
- корректность retry logic;
- корректность D1/D7 observability.

tests/dashboard_consistency.sql - проверяет, что агрегированные dashboard marts согласованы с основной пользовательской витриной.

### Error handling

Для всех задач настроено:

``` code
retries = 1
retry_delay = 2 minutes
```
После окончательного падения вызывается: `on_failure_callback`

Информация записывается в Airflow logs и в: $AIRFLOW_HOME/failure_alerts.jsonl

### Полезные команды

Проверить пустые SQL-файлы:

```code
find sql tests -type f -size 0 -print
```
Проверить последние technical alerts:

```code
tail -n 10 ~/airflow-floodit/failure_alerts.jsonl
```

Проверить product alerts:

```code
tail -n 10 ~/airflow-floodit/product_alerts.log
```

Проверить SQL-файлы в Cloud Shell:
```code
gcloud cloud-shell ssh \
  --authorize-session \
  --command='find /home/g1234567kazakova/floodit-airflow -maxdepth 4 -type f | sort'
```