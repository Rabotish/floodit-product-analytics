-- 1. Количество дневных таблиц и границы периода

WITH event_tables AS (
    SELECT
        table_name,
        PARSE_DATE(
            '%Y%m%d',
            REGEXP_EXTRACT(table_name, r'^events_(\d{8})$')
        ) AS table_date
    FROM `firebase-public-project.analytics_153293282.INFORMATION_SCHEMA.TABLES`
    WHERE REGEXP_CONTAINS(table_name, r'^events_\d{8}$')
)

SELECT
    COUNT(*) AS table_count,
    MIN(table_date) AS min_table_date,
    MAX(table_date) AS max_table_date
FROM event_tables;


-- 2. Поиск пропущенных дневных таблиц внутри периода

WITH event_tables AS (
    SELECT
        PARSE_DATE(
            '%Y%m%d',
            REGEXP_EXTRACT(table_name, r'^events_(\d{8})$')
        ) AS table_date
    FROM `firebase-public-project.analytics_153293282.INFORMATION_SCHEMA.TABLES`
    WHERE REGEXP_CONTAINS(table_name, r'^events_\d{8}$')
),

date_bounds AS (
    SELECT
        MIN(table_date) AS min_date,
        MAX(table_date) AS max_date
    FROM event_tables
),

calendar AS (
    SELECT date
    FROM date_bounds,
    UNNEST(GENERATE_DATE_ARRAY(min_date, max_date)) AS date
)

SELECT
    calendar.date AS missing_date
FROM calendar
LEFT JOIN event_tables
    ON calendar.date = event_tables.table_date
WHERE event_tables.table_date IS NULL
ORDER BY missing_date;

-- 3. Объём данных по дневным таблицам

SELECT
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS table_date,
    COUNT(*) AS event_count,
    COUNT(DISTINCT user_pseudo_id) AS user_count
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
GROUP BY table_date
ORDER BY table_date;

-- 4. Проверка соответствия event_date дневной таблице

SELECT
    _TABLE_SUFFIX AS table_suffix,
    COUNT(*) AS event_count,
    COUNTIF(event_date IS NULL) AS null_event_date_count,
    COUNTIF(event_date != _TABLE_SUFFIX) AS mismatched_event_date_count
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
GROUP BY table_suffix
HAVING
    null_event_date_count > 0
    OR mismatched_event_date_count > 0
ORDER BY table_suffix;

-- 5. Проверка распределения количества событий по дневным таблицам

WITH daily_stats AS (
    SELECT
        PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS table_date,
        COUNT(*) AS event_count
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    GROUP BY table_date
)

SELECT
    MIN(event_count) AS min_event_count,
    MAX(event_count) AS max_event_count,
    COUNT(DISTINCT event_count) AS distinct_event_counts,
    COUNTIF(event_count = 50000) AS tables_with_50000_events,
    COUNT(*) AS table_count
FROM daily_stats;