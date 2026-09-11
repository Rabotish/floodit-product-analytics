-- 1. Проверка полноты аналитически значимых event_params

WITH expected_params AS (

    SELECT *
    FROM UNNEST([

        -- Progressive gameplay
        STRUCT('level_start' AS event_name, 'level' AS param_key),
        STRUCT('level_start', 'level_name'),

        STRUCT('level_complete', 'level'),
        STRUCT('level_complete', 'level_name'),

        STRUCT('level_fail', 'level'),
        STRUCT('level_fail', 'level_name'),

        STRUCT('level_retry', 'level'),
        STRUCT('level_retry', 'level_name'),

        STRUCT('level_reset', 'level'),
        STRUCT('level_reset', 'level_name'),

        STRUCT('level_end', 'level'),
        STRUCT('level_end', 'level_name'),

        -- Quickplay
        STRUCT('level_start_quickplay', 'board'),
        STRUCT('level_complete_quickplay', 'board'),
        STRUCT('level_fail_quickplay', 'board'),
        STRUCT('level_retry_quickplay', 'board'),
        STRUCT('level_reset_quickplay', 'board'),
        STRUCT('level_end_quickplay', 'board'),

        -- Monetization
        STRUCT('in_app_purchase', 'product_id'),
        STRUCT('in_app_purchase', 'price'),
        STRUCT('in_app_purchase', 'currency'),
        STRUCT('in_app_purchase', 'quantity'),

        -- Engagement
        STRUCT('user_engagement', 'engagement_time_msec')
    ])

),

event_counts AS (

    SELECT
        event_name,
        COUNT(*) AS event_count
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name IN (
        SELECT DISTINCT event_name
        FROM expected_params
    )
    GROUP BY event_name

),

param_counts AS (

    SELECT
        e.event_name,
        p.key AS param_key,
        COUNT(*) AS events_with_param

    FROM `firebase-public-project.analytics_153293282.events_*` AS e,
    UNNEST(e.event_params) AS p

    JOIN expected_params AS x
        ON e.event_name = x.event_name
       AND p.key = x.param_key

    GROUP BY
        e.event_name,
        p.key
)

SELECT
    x.event_name,
    x.param_key,

    c.event_count,

    COALESCE(p.events_with_param, 0) AS events_with_param,

    c.event_count - COALESCE(p.events_with_param, 0)
        AS events_without_param,

    ROUND(
        SAFE_DIVIDE(
            COALESCE(p.events_with_param, 0),
            c.event_count
        ) * 100,
        2
    ) AS coverage_pct

FROM expected_params AS x

JOIN event_counts AS c
    USING (event_name)

LEFT JOIN param_counts AS p
    USING (event_name, param_key)

ORDER BY
    event_name,
    param_key;

-- 2. Проверка полноты level_up и completed_5_levels

SELECT
    event_name,
    COUNT(*) AS event_count,

    COUNTIF(
        EXISTS (
            SELECT 1
            FROM UNNEST(event_params)
            WHERE key = 'level'
        )
    ) AS with_level,

    COUNTIF(
        EXISTS (
            SELECT 1
            FROM UNNEST(event_params)
            WHERE key = 'level_name'
        )
    ) AS with_level_name,

    COUNTIF(
        EXISTS (
            SELECT 1
            FROM UNNEST(event_params)
            WHERE key = 'value'
        )
    ) AS with_value

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name IN (
    'level_up',
    'completed_5_levels'
)

GROUP BY event_name
ORDER BY event_name;

-- 3. Проверка post_scope

SELECT
    COUNT(*) AS event_count,

    COUNTIF(
        EXISTS (
            SELECT 1
            FROM UNNEST(event_params)
            WHERE key = 'score'
        )
    ) AS with_score,

    COUNTIF(
        EXISTS (
            SELECT 1
            FROM UNNEST(event_params)
            WHERE key = 'level'
        )
    ) AS with_level,

    COUNTIF(
        EXISTS (
            SELECT 1
            FROM UNNEST(event_params)
            WHERE key = 'level_name'
        )
    ) AS with_level_name

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name = 'post_score';


-- 4. Совместная заполненность level и level_name

WITH gameplay AS (
    SELECT
        event_name,

        EXISTS (
            SELECT 1
            FROM UNNEST(event_params)
            WHERE key = 'level'
        ) AS has_level,

        EXISTS (
            SELECT 1
            FROM UNNEST(event_params)
            WHERE key = 'level_name'
        ) AS has_level_name

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

    COUNT(*) AS event_count,

    COUNTIF(has_level AND has_level_name)
        AS both_present,

    COUNTIF(has_level AND NOT has_level_name)
        AS only_level,

    COUNTIF(NOT has_level AND has_level_name)
        AS only_level_name,

    COUNTIF(NOT has_level AND NOT has_level_name)
        AS neither_present

FROM gameplay

GROUP BY event_name
ORDER BY event_name;