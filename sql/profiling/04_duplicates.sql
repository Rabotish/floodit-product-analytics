-- 1. Поиск повторов по технической сигнатуре события

WITH duplicate_groups AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,
        COUNT(*) AS row_count
    FROM `firebase-public-project.analytics_153293282.events_*`
    GROUP BY
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS duplicate_groups,
    SUM(row_count) AS rows_in_duplicate_groups,
    SUM(row_count - 1) AS potential_duplicate_rows,
    MAX(row_count) AS max_rows_per_group
FROM duplicate_groups;

-- 2. Полностью идентичные записи

WITH rows_ AS (
    SELECT
        FARM_FINGERPRINT(TO_JSON_STRING(t)) AS row_hash
    FROM `firebase-public-project.analytics_153293282.events_*` AS t
),

duplicates AS (
    SELECT
        row_hash,
        COUNT(*) AS row_count
    FROM rows_
    GROUP BY row_hash
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS duplicate_groups,
    SUM(row_count) AS rows_in_duplicate_groups,
    SUM(row_count - 1) AS exact_duplicate_rows,
    MAX(row_count) AS max_rows_per_group
FROM duplicates;


-- 3. Повтор одного event_params.key внутри одного события

WITH events AS (
    SELECT
        ARRAY_LENGTH(event_params) AS params_count,

        (
            SELECT COUNT(DISTINCT p.key)
            FROM UNNEST(event_params) AS p
        ) AS distinct_keys_count

    FROM `firebase-public-project.analytics_153293282.events_*`
)

SELECT
    COUNTIF(
        params_count > distinct_keys_count
    ) AS events_with_duplicated_param_keys,

    SUM(
        params_count - distinct_keys_count
    ) AS additional_parameter_values,

    MAX(
        params_count - distinct_keys_count
    ) AS max_additional_keys_per_event

FROM events;

-- 4. Уникальность user_properties.key

WITH events AS (
    SELECT
        ARRAY_LENGTH(user_properties) AS properties_count,

        (
            SELECT COUNT(DISTINCT p.key)
            FROM UNNEST(user_properties) AS p
        ) AS distinct_keys_count

    FROM `firebase-public-project.analytics_153293282.events_*`
)

SELECT
    COUNTIF(
        properties_count > distinct_keys_count
    ) AS events_with_duplicated_property_keys,

    SUM(
        properties_count - distinct_keys_count
    ) AS additional_property_values,

    MAX(
        properties_count - distinct_keys_count
    ) AS max_additional_keys_per_event

FROM events;

-- 5. Распределение 59 полных дублей по событиям

WITH events AS (
    SELECT
        event_name,
        event_date,
        TO_JSON_STRING(t) AS row_data
    FROM `firebase-public-project.analytics_153293282.events_*` AS t
),

duplicates AS (
    SELECT
        ANY_VALUE(event_name) AS event_name,
        ANY_VALUE(event_date) AS event_date,
        COUNT(*) AS row_count
    FROM events
    GROUP BY row_data
    HAVING COUNT(*) > 1
)

SELECT
    event_name,
    COUNT(*) AS duplicate_groups,
    SUM(row_count - 1) AS duplicate_rows
FROM duplicates
GROUP BY event_name
ORDER BY duplicate_rows DESC, event_name;

