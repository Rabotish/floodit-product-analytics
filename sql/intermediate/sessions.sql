CREATE OR REPLACE TABLE `sixth-tempo-506411-d9.floodit_analytics.sessions`
CLUSTER BY user_pseudo_id
AS

WITH cohort_events AS (
    SELECT
        e.user_pseudo_id,
        e.event_timestamp,
        e.event_name
    FROM `sixth-tempo-506411-d9.floodit_analytics.stg_events` AS e
    INNER JOIN `sixth-tempo-506411-d9.floodit_analytics.users` AS u
        USING (user_pseudo_id)
),

timestamp_points AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        COUNTIF(event_name = 'session_start') > 0 AS has_session_start
    FROM cohort_events
    GROUP BY
        user_pseudo_id,
        event_timestamp
),

ordered_points AS (
    SELECT
        *,
        LAG(event_timestamp) OVER (
            PARTITION BY user_pseudo_id
            ORDER BY event_timestamp
        ) AS previous_timestamp
    FROM timestamp_points
),

session_boundaries AS (
    SELECT
        *,
        CASE
            WHEN previous_timestamp IS NULL THEN 1
            WHEN has_session_start THEN 1
            WHEN TIMESTAMP_DIFF(
                event_timestamp,
                previous_timestamp,
                MICROSECOND
            ) > 1800000000 THEN 1
            ELSE 0
        END AS is_new_session
    FROM ordered_points
),

numbered_points AS (
    SELECT
        *,
        SUM(is_new_session) OVER (
            PARTITION BY user_pseudo_id
            ORDER BY event_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS session_number
    FROM session_boundaries
),

aggregated_sessions AS (
    SELECT
        user_pseudo_id,
        session_number,
        MIN(event_timestamp) AS session_start_timestamp,
        MAX(event_timestamp) AS session_end_timestamp
    FROM numbered_points
    GROUP BY
        user_pseudo_id,
        session_number
)

SELECT
    TO_HEX(
        SHA256(
            TO_JSON_STRING(
                STRUCT(
                    user_pseudo_id,
                    session_start_timestamp
                )
            )
        )
    ) AS session_id,

    user_pseudo_id,
    session_number,
    session_start_timestamp,
    session_end_timestamp

FROM aggregated_sessions;