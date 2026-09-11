-- 1. Соответствие level и level_name

WITH gameplay AS (
    SELECT
        event_name,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                )
                AS INT64
            )
        ) AS level,

        (
            SELECT ANY_VALUE(p.value.string_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'level_name'
        ) AS level_name

    FROM `firebase-public-project.analytics_153293282.events_*`

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_retry',
        'level_reset',
        'level_end',
        'level_up',
        'completed_5_levels',
        'post_score'
    )
)

SELECT
    event_name,
    COUNT(*) AS events_with_both,

    COUNTIF(
        level_name = CONCAT('level_', CAST(level AS STRING))
    ) AS matching,

    COUNTIF(
        level_name != CONCAT('level_', CAST(level AS STRING))
    ) AS mismatching

FROM gameplay

WHERE level IS NOT NULL
  AND level_name IS NOT NULL

GROUP BY event_name
ORDER BY event_name;


-- 2. Соответствие platform и идентификаторов приложения

SELECT
    platform,
    app_info.id AS app_id,
    app_info.firebase_app_id AS firebase_app_id,

    COUNT(*) AS event_count,
    COUNT(DISTINCT user_pseudo_id) AS user_count

FROM `firebase-public-project.analytics_153293282.events_*`

GROUP BY
    platform,
    app_id,
    firebase_app_id

ORDER BY event_count DESC;


-- 2.1. Однозначность platform и app_info

WITH combinations AS (
    SELECT DISTINCT
        platform,
        app_info.id AS app_id,
        app_info.firebase_app_id AS firebase_app_id
    FROM `firebase-public-project.analytics_153293282.events_*`
)

SELECT
    platform,

    COUNT(DISTINCT app_id)
        AS app_ids,

    COUNT(DISTINCT firebase_app_id)
        AS firebase_app_ids

FROM combinations

GROUP BY platform
ORDER BY platform;


-- 3. Соответствие platform, install_store и install_source

SELECT
    platform,
    app_info.install_store AS install_store,
    app_info.install_source AS install_source,

    COUNT(*) AS event_count,
    COUNT(DISTINCT user_pseudo_id) AS user_count

FROM `firebase-public-project.analytics_153293282.events_*`

GROUP BY
    platform,
    install_store,
    install_source

ORDER BY
    platform,
    event_count DESC;


-- 3.1. Временное распределение install_store / install_source

SELECT
    platform,

    CASE
        WHEN app_info.install_store IS NOT NULL
            THEN 'install_store'
        WHEN app_info.install_source IS NOT NULL
            THEN 'install_source'
        ELSE 'missing'
    END AS populated_field,

    MIN(PARSE_DATE('%Y%m%d', event_date)) AS min_date,
    MAX(PARSE_DATE('%Y%m%d', event_date)) AS max_date,

    COUNT(DISTINCT event_date) AS active_days,
    COUNT(*) AS event_count,
    COUNT(DISTINCT user_pseudo_id) AS user_count

FROM `firebase-public-project.analytics_153293282.events_*`

GROUP BY
    platform,
    populated_field

ORDER BY
    platform,
    min_date;

-- 4. Соответствие platform и device.operating_system

SELECT
    platform,
    device.operating_system AS operating_system,

    COUNT(*) AS event_count,
    COUNT(DISTINCT user_pseudo_id) AS user_count

FROM `firebase-public-project.analytics_153293282.events_*`

GROUP BY
    platform,
    operating_system

ORDER BY
    platform,
    event_count DESC;


-- 4.1. Несоответствия platform и operating_system

SELECT
    COUNT(*) AS event_count,

    COUNTIF(device.operating_system IS NULL)
        AS null_operating_system,

    COUNTIF(
        device.operating_system IS NOT NULL
        AND platform != device.operating_system
    ) AS mismatching_platform_os

FROM `firebase-public-project.analytics_153293282.events_*`;


-- 4.2. Связь NULL operating_system с изменением app_info schema

SELECT
    COUNT(*) AS event_count,

    COUNTIF(
        device.operating_system IS NULL
        AND app_info.install_store IS NOT NULL
        AND app_info.install_source IS NULL
    ) AS null_os_old_schema,

    COUNTIF(
        device.operating_system IS NULL
        AND app_info.install_source IS NOT NULL
    ) AS null_os_new_schema,

    COUNTIF(
        device.operating_system IS NOT NULL
        AND app_info.install_store IS NOT NULL
    ) AS filled_os_old_schema,

    COUNTIF(
        device.operating_system IS NOT NULL
        AND app_info.install_source IS NOT NULL
    ) AS filled_os_new_schema

FROM `firebase-public-project.analytics_153293282.events_*`;