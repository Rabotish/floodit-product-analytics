WITH latest_date AS (
    SELECT
        MAX(metric_date) AS metric_date

    FROM
        `sixth-tempo-506411-d9.floodit_analytics.mart_product_monitoring`
)

SELECT
    CONCAT(
        'PRODUCT_ANOMALY_ALERT|',
        CAST(m.metric_date AS STRING),
        '|',
        m.metric_name,
        '|',
        CASE
            WHEN m.metric_value < m.lower_bound
                THEN 'DOWN'
            ELSE 'UP'
        END,
        '|value=',
        FORMAT('%.4f', m.metric_value),
        '|baseline=',
        FORMAT('%.4f', m.baseline_median),
        '|lower=',
        FORMAT('%.4f', m.lower_bound),
        '|upper=',
        FORMAT('%.4f', m.upper_bound),
        '|denominator=',
        CAST(m.denominator AS STRING)
    ) AS alert

FROM
    `sixth-tempo-506411-d9.floodit_analytics.mart_product_monitoring` AS m

JOIN latest_date AS d
    ON m.metric_date = d.metric_date

WHERE
    m.is_anomaly

ORDER BY
    m.metric_name;