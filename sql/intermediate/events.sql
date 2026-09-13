CREATE OR REPLACE TABLE `sixth-tempo-506411-d9.floodit_analytics.events`
CLUSTER BY user_pseudo_id, event_name
AS

WITH sessionized_events AS (
    SELECT
        e.stg_event_id,
        e.user_pseudo_id,
        s.session_id,
        e.event_timestamp,
        e.event_name

    FROM `sixth-tempo-506411-d9.floodit_analytics.stg_events` AS e

    INNER JOIN `sixth-tempo-506411-d9.floodit_analytics.sessions` AS s
        ON e.user_pseudo_id = s.user_pseudo_id
       AND e.event_timestamp BETWEEN
           s.session_start_timestamp
           AND s.session_end_timestamp
),

classified_events AS (
    SELECT
        *,

        CASE
            WHEN event_name IN (
                'level_start',
                'level_complete',
                'level_fail',
                'level_retry',
                'level_reset',
                'level_end',
                'level_up',
                'level_start_quickplay',
                'level_complete_quickplay',
                'level_fail_quickplay',
                'level_retry_quickplay',
                'level_reset_quickplay',
                'level_end_quickplay',
                'completed_5_levels'
            )
                THEN 'gameplay'

            WHEN event_name IN (
                'in_app_purchase',
                'spend_virtual_currency',
                'ad_reward',
                'use_extra_steps',
                'no_more_extra_steps'
            )
                THEN 'monetization'

            WHEN event_name IN (
                'firebase_campaign',
                'dynamic_link_app_open',
                'dynamic_link_first_open'
            )
                THEN 'acquisition'

            WHEN event_name IN (
                'first_open',
                'session_start',
                'user_engagement',
                'screen_view',
                'select_content',
                'challenge_accepted',
                'challenge_a_friend',
                'post_score'
            )
                THEN 'user_interaction'

            WHEN event_name IN (
                'app_update',
                'app_remove',
                'app_clear_data',
                'os_update',
                'app_exception',
                'error',
                'notification_foreground'
            )
                THEN 'system'

            ELSE 'unknown'
        END AS event_group

    FROM sessionized_events
),

ranked_events AS (
    SELECT
        *,

        CASE
            WHEN event_group = 'gameplay'
            THEN ROW_NUMBER() OVER (
                PARTITION BY
                    user_pseudo_id,
                    event_timestamp,
                    event_name
                ORDER BY stg_event_id
            )
        END AS gameplay_rank

    FROM classified_events
)

SELECT
    stg_event_id AS event_id,
    user_pseudo_id,
    session_id,
    event_timestamp,
    event_name,
    event_group

FROM ranked_events

WHERE event_group != 'gameplay'
   OR gameplay_rank = 1;