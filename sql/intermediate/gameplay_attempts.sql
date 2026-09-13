CREATE OR REPLACE TABLE `sixth-tempo-506411-d9.floodit_analytics.gameplay_attempts`
CLUSTER BY user_pseudo_id, session_id
AS

WITH gameplay_events AS (
    SELECT
        e.event_id,
        e.user_pseudo_id,
        e.session_id,
        e.event_timestamp,
        e.event_name,

        CASE
            WHEN e.event_name IN (
                'level_start',
                'level_complete',
                'level_fail',
                'level_end'
            )
                THEN 'progressive'

            WHEN e.event_name IN (
                'level_start_quickplay',
                'level_complete_quickplay',
                'level_fail_quickplay',
                'level_end_quickplay'
            )
                THEN 'quickplay'
        END AS game_mode,

        CASE
            WHEN e.event_name IN (
                'level_start',
                'level_start_quickplay'
            )
                THEN 'start'

            WHEN e.event_name IN (
                'level_complete',
                'level_complete_quickplay'
            )
                THEN 'complete'

            WHEN e.event_name IN (
                'level_fail',
                'level_fail_quickplay'
            )
                THEN 'fail'

            WHEN e.event_name IN (
                'level_end',
                'level_end_quickplay'
            )
                THEN 'end'
        END AS gameplay_event_type,

        CASE
            WHEN e.event_name IN (
                'level_start',
                'level_complete',
                'level_fail',
                'level_end'
            )
            THEN CAST((
                SELECT
                    COALESCE(
                        ep.value.int_value,
                        CAST(ep.value.double_value AS INT64)
                    )
                FROM UNNEST(s.event_params) AS ep
                WHERE ep.key = 'level'
            ) AS STRING)

            WHEN e.event_name IN (
                'level_start_quickplay',
                'level_complete_quickplay',
                'level_fail_quickplay',
                'level_end_quickplay'
            )
            THEN (
                SELECT ep.value.string_value
                FROM UNNEST(s.event_params) AS ep
                WHERE ep.key = 'board'
            )
        END AS game_key

    FROM `sixth-tempo-506411-d9.floodit_analytics.events` AS e

    INNER JOIN `sixth-tempo-506411-d9.floodit_analytics.stg_events` AS s
        ON e.event_id = s.stg_event_id

    WHERE e.event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay'
    )
),

starts AS (
    SELECT
        event_id AS start_event_id,
        user_pseudo_id,
        session_id,
        event_timestamp AS start_timestamp,
        game_mode,
        game_key
    FROM gameplay_events
    WHERE gameplay_event_type = 'start'
),

terminals AS (
    SELECT
        event_id AS terminal_event_id,
        user_pseudo_id,
        session_id,
        event_timestamp AS terminal_timestamp,
        gameplay_event_type,
        game_mode,
        game_key
    FROM gameplay_events
    WHERE gameplay_event_type IN (
        'complete',
        'fail',
        'end'
    )
),

candidate_matches AS (
    SELECT
        t.*,
        s.start_event_id,

        ROW_NUMBER() OVER (
            PARTITION BY t.terminal_event_id
            ORDER BY
                s.start_timestamp DESC,
                s.start_event_id
        ) AS match_rank

    FROM terminals AS t

    INNER JOIN starts AS s
        ON t.user_pseudo_id = s.user_pseudo_id
       AND t.session_id = s.session_id
       AND t.game_mode = s.game_mode
       AND t.game_key = s.game_key
       AND s.start_timestamp < t.terminal_timestamp
       AND TIMESTAMP_DIFF(
            t.terminal_timestamp,
            s.start_timestamp,
            MICROSECOND
       ) <= 1800000000
),

matched_terminals AS (
    SELECT
        *
    FROM candidate_matches
    WHERE match_rank = 1
),

first_explicit_results AS (
    SELECT
        start_event_id,

        ARRAY_AGG(
            STRUCT(
                terminal_event_id AS result_event_id,
                terminal_timestamp AS result_timestamp,
                gameplay_event_type
            )
            ORDER BY
                terminal_timestamp,
                terminal_event_id
            LIMIT 1
        )[OFFSET(0)] AS first_result

    FROM matched_terminals

    WHERE gameplay_event_type IN (
        'complete',
        'fail'
    )

    GROUP BY start_event_id
),

attempts_with_end AS (
    SELECT DISTINCT
        start_event_id
    FROM matched_terminals
    WHERE gameplay_event_type = 'end'
)

SELECT
    TO_HEX(
        SHA256(
            CONCAT(
                'attempt|',
                s.start_event_id
            )
        )
    ) AS attempt_id,

    s.user_pseudo_id,
    s.session_id,
    s.start_event_id,

    r.first_result.result_event_id AS result_event_id,

    CASE
        WHEN r.first_result.gameplay_event_type = 'complete'
            THEN 'success'

        WHEN r.first_result.gameplay_event_type = 'fail'
            THEN 'fail'

        ELSE 'unknown'
    END AS outcome

FROM starts AS s

LEFT JOIN first_explicit_results AS r
    USING (start_event_id)

LEFT JOIN attempts_with_end AS ae
    USING (start_event_id);