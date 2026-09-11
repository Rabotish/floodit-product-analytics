-- 1. Фактическое использование веток event_params.value

SELECT
    p.key,

    COUNT(*) AS parameter_count,

    COUNTIF(p.value.string_value IS NOT NULL)
        AS string_value_count,

    COUNTIF(p.value.int_value IS NOT NULL)
        AS int_value_count,

    COUNTIF(p.value.float_value IS NOT NULL)
        AS float_value_count,

    COUNTIF(p.value.double_value IS NOT NULL)
        AS double_value_count

FROM `firebase-public-project.analytics_153293282.events_*` AS e,
UNNEST(e.event_params) AS p

GROUP BY p.key
ORDER BY p.key;


-- 2. Проверка одновременного заполнения нескольких value-полей

WITH params AS (
    SELECT
        p.key,

        CAST(p.value.string_value IS NOT NULL AS INT64)
        + CAST(p.value.int_value IS NOT NULL AS INT64)
        + CAST(p.value.float_value IS NOT NULL AS INT64)
        + CAST(p.value.double_value IS NOT NULL AS INT64)
            AS filled_value_fields

    FROM `firebase-public-project.analytics_153293282.events_*` AS e,
    UNNEST(e.event_params) AS p
)

SELECT
    key,

    COUNT(*) AS parameter_count,

    COUNTIF(filled_value_fields = 0)
        AS values_without_any_type,

    COUNTIF(filled_value_fields = 1)
        AS values_with_one_type,

    COUNTIF(filled_value_fields > 1)
        AS values_with_multiple_types,

    MAX(filled_value_fields)
        AS max_filled_types

FROM params

GROUP BY key
ORDER BY key;


-- 3. Нормализуемые числовые параметры

SELECT
    p.key,

    COUNT(*) AS parameter_count,

    COUNTIF(p.value.int_value IS NOT NULL)
        AS int_count,

    COUNTIF(p.value.float_value IS NOT NULL)
        AS float_count,

    COUNTIF(p.value.double_value IS NOT NULL)
        AS double_count,

    COUNTIF(
        p.value.int_value IS NULL
        AND p.value.float_value IS NULL
        AND p.value.double_value IS NULL
    ) AS missing_numeric_value

FROM `firebase-public-project.analytics_153293282.events_*` AS e,
UNNEST(e.event_params) AS p

WHERE p.key IN (
    'firebase_screen_id',
    'level',
    'score',
    'time',
    'value'
)

GROUP BY p.key
ORDER BY p.key;


-- 4. Проверка дробной части double_value

SELECT
    p.key,

    COUNTIF(
        p.value.double_value IS NOT NULL
    ) AS double_value_count,

    COUNTIF(
        p.value.double_value IS NOT NULL
        AND p.value.double_value != TRUNC(p.value.double_value)
    ) AS fractional_double_values,

    MIN(p.value.double_value) AS min_double_value,
    MAX(p.value.double_value) AS max_double_value

FROM `firebase-public-project.analytics_153293282.events_*` AS e,
UNNEST(e.event_params) AS p

WHERE p.key IN (
    'firebase_screen_id',
    'level',
    'score',
    'time',
    'value'
)

GROUP BY p.key
ORDER BY p.key;