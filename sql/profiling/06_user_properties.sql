-- 1. Фактические типы user_properties.value

SELECT
    p.key,

    COUNT(*) AS property_count,

    COUNTIF(p.value.string_value IS NOT NULL)
        AS string_value_count,

    COUNTIF(p.value.int_value IS NOT NULL)
        AS int_value_count,

    COUNTIF(p.value.float_value IS NOT NULL)
        AS float_value_count,

    COUNTIF(p.value.double_value IS NOT NULL)
        AS double_value_count,

    COUNTIF(p.value.set_timestamp_micros IS NOT NULL)
        AS set_timestamp_count

FROM `firebase-public-project.analytics_153293282.events_*` AS e,
UNNEST(e.user_properties) AS p

GROUP BY p.key
ORDER BY p.key;


-- 2. Согласованность типизированного значения свойства

WITH properties AS (
    SELECT
        p.key,

        CAST(p.value.string_value IS NOT NULL AS INT64)
        + CAST(p.value.int_value IS NOT NULL AS INT64)
        + CAST(p.value.float_value IS NOT NULL AS INT64)
        + CAST(p.value.double_value IS NOT NULL AS INT64)
            AS filled_value_fields,

        p.value.set_timestamp_micros

    FROM `firebase-public-project.analytics_153293282.events_*` AS e,
    UNNEST(e.user_properties) AS p
)

SELECT
    key,

    COUNT(*) AS property_count,

    COUNTIF(filled_value_fields = 0)
        AS values_without_type,

    COUNTIF(filled_value_fields = 1)
        AS values_with_one_type,

    COUNTIF(filled_value_fields > 1)
        AS values_with_multiple_types,

    COUNTIF(set_timestamp_micros IS NULL)
        AS missing_set_timestamp

FROM properties

GROUP BY key
ORDER BY key;


-- 3. Изменение user_property внутри одного пользователя

WITH properties AS (
    SELECT
        e.user_pseudo_id,
        p.key,

        COALESCE(
            p.value.string_value,
            CAST(p.value.int_value AS STRING),
            CAST(p.value.float_value AS STRING),
            CAST(p.value.double_value AS STRING)
        ) AS property_value

    FROM `firebase-public-project.analytics_153293282.events_*` AS e,
    UNNEST(e.user_properties) AS p

    WHERE e.user_pseudo_id IS NOT NULL
),

user_properties AS (
    SELECT
        user_pseudo_id,
        key,
        COUNT(DISTINCT property_value) AS distinct_values
    FROM properties
    GROUP BY user_pseudo_id, key
)

SELECT
    key,

    COUNT(*) AS users_with_property,

    COUNTIF(distinct_values = 1)
        AS users_with_one_value,

    COUNTIF(distinct_values > 1)
        AS users_with_multiple_values,

    MAX(distinct_values)
        AS max_values_per_user

FROM user_properties

GROUP BY key
ORDER BY key;


-- 4. Стабильность экспериментальных групп Firebase

WITH experiments AS (
    SELECT
        e.user_pseudo_id,
        p.key,
        p.value.string_value AS experiment_group
    FROM `firebase-public-project.analytics_153293282.events_*` AS e,
    UNNEST(e.user_properties) AS p
    WHERE p.key LIKE 'firebase_exp_%'
),

users AS (
    SELECT
        user_pseudo_id,
        key,
        COUNT(DISTINCT experiment_group) AS group_count
    FROM experiments
    GROUP BY user_pseudo_id, key
)

SELECT
    key,
    COUNT(*) AS users_in_experiment,
    COUNTIF(group_count = 1) AS users_with_one_group,
    COUNTIF(group_count > 1) AS users_with_multiple_groups,
    MAX(group_count) AS max_groups_per_user
FROM users
GROUP BY key
ORDER BY key;

-- 5. Покрытие user_properties по пользователям

WITH users AS (
    SELECT DISTINCT
        user_pseudo_id
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE user_pseudo_id IS NOT NULL
),

property_coverage AS (
    SELECT
        p.key,
        COUNT(DISTINCT e.user_pseudo_id) AS users_with_property
    FROM `firebase-public-project.analytics_153293282.events_*` AS e,
    UNNEST(e.user_properties) AS p
    WHERE e.user_pseudo_id IS NOT NULL
    GROUP BY p.key
)

SELECT
    p.key,
    p.users_with_property,
    COUNT(*) OVER () AS property_count,

    (SELECT COUNT(*) FROM users)
        AS total_users,

    ROUND(
        100 * SAFE_DIVIDE(
            p.users_with_property,
            (SELECT COUNT(*) FROM users)
        ),
        2
    ) AS user_coverage_pct

FROM property_coverage AS p

ORDER BY
    users_with_property DESC,
    key;

-- 6. Согласованность first_open_time и user_first_touch_timestamp

WITH users AS (
    SELECT
        user_pseudo_id,
        MIN(user_first_touch_timestamp)
            AS user_first_touch_timestamp
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE user_pseudo_id IS NOT NULL
    GROUP BY user_pseudo_id
),

first_open_property AS (
    SELECT
        e.user_pseudo_id,

        COUNT(DISTINCT p.value.int_value)
            AS distinct_first_open_times,

        MIN(p.value.int_value)
            AS first_open_time

    FROM `firebase-public-project.analytics_153293282.events_*` AS e,
    UNNEST(e.user_properties) AS p

    WHERE p.key = 'first_open_time'
      AND e.user_pseudo_id IS NOT NULL

    GROUP BY e.user_pseudo_id
)

SELECT
    COUNT(*) AS user_count,

    COUNTIF(p.user_pseudo_id IS NULL)
        AS users_without_first_open_time,

    COUNTIF(p.distinct_first_open_times = 1)
        AS users_with_one_first_open_time,

    COUNTIF(p.distinct_first_open_times > 1)
        AS users_with_multiple_first_open_times,

    COUNTIF(
        p.first_open_time = u.user_first_touch_timestamp
    ) AS exact_matches,

    COUNTIF(
        p.first_open_time IS DISTINCT FROM
        u.user_first_touch_timestamp
    ) AS mismatches

FROM users AS u

LEFT JOIN first_open_property AS p
    USING (user_pseudo_id);