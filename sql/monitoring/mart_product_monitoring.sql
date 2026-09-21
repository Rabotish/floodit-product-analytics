CREATE OR REPLACE TABLE
    `sixth-tempo-506411-d9.floodit_analytics.mart_product_monitoring`
AS

WITH daily_metrics AS (
    SELECT
        cohort_date AS metric_date,

        SUM(new_users) AS new_users,
        SUM(first_result_users) AS first_result_users,
        SUM(activated_users) AS activated_users,
        SUM(d1_observable_users) AS d1_observable_users,
        SUM(d1_retained_users) AS d1_retained_users

    FROM
        `sixth-tempo-506411-d9.floodit_analytics.mart_dashboard_overview`

    GROUP BY
        cohort_date
),

metrics_long AS (

    SELECT
        metric_date,
        'first_result_reach' AS metric_name,
        first_result_users AS numerator,
        new_users AS denominator,
        SAFE_DIVIDE(
            first_result_users,
            new_users
        ) AS metric_value

    FROM daily_metrics

    UNION ALL

    SELECT
        metric_date,
        'activation_rate' AS metric_name,
        activated_users AS numerator,
        first_result_users AS denominator,
        SAFE_DIVIDE(
            activated_users,
            first_result_users
        ) AS metric_value

    FROM daily_metrics

    UNION ALL

    SELECT
        metric_date,
        'd1_retention' AS metric_name,
        d1_retained_users AS numerator,
        d1_observable_users AS denominator,
        SAFE_DIVIDE(
            d1_retained_users,
            d1_observable_users
        ) AS metric_value

    FROM daily_metrics
),

history AS (
    SELECT
        curr.metric_date,
        curr.metric_name,
        curr.numerator,
        curr.denominator,
        curr.metric_value,

        ARRAY_AGG(
            prev.metric_value
            IGNORE NULLS
            ORDER BY prev.metric_date
        ) AS history_values

    FROM metrics_long AS curr

    LEFT JOIN metrics_long AS prev
        ON curr.metric_name = prev.metric_name
        AND prev.metric_date BETWEEN
            DATE_SUB(curr.metric_date, INTERVAL 14 DAY)
            AND DATE_SUB(curr.metric_date, INTERVAL 1 DAY)

    GROUP BY
        curr.metric_date,
        curr.metric_name,
        curr.numerator,
        curr.denominator,
        curr.metric_value
),

median_baseline AS (
    SELECT
        *,

        COALESCE(
            ARRAY_LENGTH(history_values),
            0
        ) AS history_points,

        (
            SELECT
                APPROX_QUANTILES(
                    value,
                    100
                )[OFFSET(50)]

            FROM UNNEST(history_values) AS value
        ) AS baseline_median

    FROM history
),

mad_baseline AS (
    SELECT
        *,

        (
            SELECT
                APPROX_QUANTILES(
                    ABS(value - baseline_median),
                    100
                )[OFFSET(50)]

            FROM UNNEST(history_values) AS value
        ) AS baseline_mad

    FROM median_baseline
),

bounds AS (
    SELECT
        *,

        GREATEST(
            0.0,
            baseline_median
                - 3 * 1.4826 * baseline_mad
        ) AS lower_bound,

        LEAST(
            1.0,
            baseline_median
                + 3 * 1.4826 * baseline_mad
        ) AS upper_bound

    FROM mad_baseline
)

SELECT
    metric_date,
    metric_name,

    numerator,
    denominator,
    metric_value,

    history_points,

    baseline_median,
    baseline_mad,

    lower_bound,
    upper_bound,

    CASE
        WHEN history_points < 7 THEN FALSE
        WHEN denominator < 30 THEN FALSE
        WHEN metric_value IS NULL THEN FALSE
        WHEN baseline_mad IS NULL THEN FALSE
        WHEN baseline_mad = 0 THEN FALSE

        WHEN metric_value < lower_bound
            OR metric_value > upper_bound
        THEN TRUE

        ELSE FALSE
    END AS is_anomaly

FROM bounds;