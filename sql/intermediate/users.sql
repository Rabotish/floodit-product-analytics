CREATE OR REPLACE TABLE `sixth-tempo-506411-d9.floodit_analytics.users`
AS

WITH dataset_bounds AS (
    SELECT
        MIN(event_date) AS min_event_date,
        MAX(event_date) AS max_event_date
    FROM `sixth-tempo-506411-d9.floodit_analytics.stg_events`
),

user_base AS (
    SELECT
        user_pseudo_id,

        MIN(user_first_touch_timestamp) AS first_touch_timestamp,

        ANY_VALUE(platform) AS platform,

        ARRAY_AGG(
            install_source IGNORE NULLS
            ORDER BY event_timestamp, stg_event_id
            LIMIT 1
        )[SAFE_OFFSET(0)] AS install_source

    FROM `sixth-tempo-506411-d9.floodit_analytics.stg_events`
    GROUP BY user_pseudo_id
)

SELECT
    user_pseudo_id,

    first_touch_timestamp,

    DATE(
        first_touch_timestamp,
        'America/Los_Angeles'
    ) AS cohort_date,

    platform,

    install_source

FROM user_base
CROSS JOIN dataset_bounds AS bounds

WHERE DATE(
    first_touch_timestamp,
    'America/Los_Angeles'
) BETWEEN bounds.min_event_date
      AND bounds.max_event_date;