CREATE OR REPLACE TABLE
    `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
AS

WITH event_enriched AS (
    SELECT
        e.event_id,
        e.user_pseudo_id,
        e.session_id,
        e.event_timestamp,
        e.event_name,
        s.event_date,
        s.event_params
    FROM `sixth-tempo-506411-d9.floodit_analytics.events` AS e
    INNER JOIN `sixth-tempo-506411-d9.floodit_analytics.stg_events` AS s
        ON e.event_id = s.stg_event_id
),

attempt_starts AS (
    SELECT
        ga.attempt_id,
        ga.user_pseudo_id,
        ga.session_id,
        ga.start_event_id,
        ga.result_event_id,
        ga.outcome,

        e.event_timestamp AS start_timestamp,

        CASE
            WHEN e.event_name = 'level_start'
                THEN 'progressive'
            WHEN e.event_name = 'level_start_quickplay'
                THEN 'quickplay'
        END AS game_mode,

        CASE
            WHEN e.event_name = 'level_start'
            THEN CAST((
                SELECT
                    COALESCE(
                        ep.value.int_value,
                        CAST(ep.value.double_value AS INT64)
                    )
                FROM UNNEST(e.event_params) AS ep
                WHERE ep.key = 'level'
            ) AS STRING)

            WHEN e.event_name = 'level_start_quickplay'
            THEN (
                SELECT ep.value.string_value
                FROM UNNEST(e.event_params) AS ep
                WHERE ep.key = 'board'
            )
        END AS game_key

    FROM `sixth-tempo-506411-d9.floodit_analytics.gameplay_attempts` AS ga

    INNER JOIN event_enriched AS e
        ON ga.start_event_id = e.event_id
),

resultative_attempts AS (
    SELECT
        a.*,
        r.event_timestamp AS result_timestamp
    FROM attempt_starts AS a

    INNER JOIN event_enriched AS r
        ON a.result_event_id = r.event_id

    WHERE a.outcome IN (
        'success',
        'fail'
    )
),

first_result AS (
    SELECT
        *
    FROM resultative_attempts

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY user_pseudo_id
        ORDER BY
            result_timestamp,
            result_event_id
    ) = 1
),

activation AS (
    SELECT
        fr.user_pseudo_id,

        COUNTIF(next_attempt.attempt_id IS NOT NULL) > 0
            AS is_activated

    FROM first_result AS fr

    LEFT JOIN attempt_starts AS next_attempt
        ON fr.user_pseudo_id = next_attempt.user_pseudo_id
       AND fr.session_id = next_attempt.session_id
       AND next_attempt.attempt_id != fr.attempt_id
       AND next_attempt.start_timestamp > fr.start_timestamp

    GROUP BY fr.user_pseudo_id
),

first_session_depth AS (
    SELECT
        ga.user_pseudo_id,
        COUNT(*) AS first_session_depth

    FROM `sixth-tempo-506411-d9.floodit_analytics.gameplay_attempts` AS ga

    INNER JOIN `sixth-tempo-506411-d9.floodit_analytics.sessions` AS s
        USING (session_id)

    WHERE s.session_number = 1
      AND ga.outcome IN (
          'success',
          'fail'
      )

    GROUP BY ga.user_pseudo_id
),

retry_after_first_fail AS (
    SELECT
        fr.user_pseudo_id,

        COUNTIF(next_attempt.attempt_id IS NOT NULL) > 0
            AS retried_after_first_fail

    FROM first_result AS fr

    LEFT JOIN attempt_starts AS next_attempt
        ON fr.user_pseudo_id = next_attempt.user_pseudo_id
       AND fr.session_id = next_attempt.session_id
       AND fr.game_mode = next_attempt.game_mode
       AND fr.game_key = next_attempt.game_key
       AND fr.attempt_id != next_attempt.attempt_id
       AND next_attempt.start_timestamp > fr.start_timestamp

    WHERE fr.outcome = 'fail'

    GROUP BY fr.user_pseudo_id
),

session_calendar AS (
    SELECT
        s.session_id,
        s.user_pseudo_id,
        s.session_number,

        ARRAY_AGG(
            e.event_date
            ORDER BY
                e.event_timestamp,
                e.event_id
            LIMIT 1
        )[OFFSET(0)] AS session_date

    FROM `sixth-tempo-506411-d9.floodit_analytics.sessions` AS s

    INNER JOIN event_enriched AS e
        USING (session_id)

    GROUP BY
        s.session_id,
        s.user_pseudo_id,
        s.session_number
),

same_day_return AS (
    SELECT
        u.user_pseudo_id,

        COUNTIF(s.session_id IS NOT NULL) > 0
            AS same_day_return

    FROM `sixth-tempo-506411-d9.floodit_analytics.users` AS u

    LEFT JOIN session_calendar AS s
        ON u.user_pseudo_id = s.user_pseudo_id
       AND s.session_number > 1
       AND s.session_date = u.cohort_date

    GROUP BY u.user_pseudo_id
),

user_event_dates AS (
    SELECT DISTINCT
        user_pseudo_id,
        event_date
    FROM event_enriched
),

dataset_bounds AS (
    SELECT
        MAX(event_date) AS max_event_date
    FROM `sixth-tempo-506411-d9.floodit_analytics.stg_events`
),

retention AS (
    SELECT
        u.user_pseudo_id,

        DATE_ADD(
            u.cohort_date,
            INTERVAL 1 DAY
        ) <= bounds.max_event_date
            AS is_d1_observable,

        CASE
            WHEN DATE_ADD(
                u.cohort_date,
                INTERVAL 1 DAY
            ) <= bounds.max_event_date
            THEN COUNTIF(
                d.event_date = DATE_ADD(
                    u.cohort_date,
                    INTERVAL 1 DAY
                )
            ) > 0
            ELSE NULL
        END AS is_d1_retained,

        DATE_ADD(
            u.cohort_date,
            INTERVAL 7 DAY
        ) <= bounds.max_event_date
            AS is_d7_observable,

        CASE
            WHEN DATE_ADD(
                u.cohort_date,
                INTERVAL 7 DAY
            ) <= bounds.max_event_date
            THEN COUNTIF(
                d.event_date = DATE_ADD(
                    u.cohort_date,
                    INTERVAL 7 DAY
                )
            ) > 0
            ELSE NULL
        END AS is_d7_retained

    FROM `sixth-tempo-506411-d9.floodit_analytics.users` AS u

    CROSS JOIN dataset_bounds AS bounds

    LEFT JOIN user_event_dates AS d
        USING (user_pseudo_id)

    GROUP BY
        u.user_pseudo_id,
        u.cohort_date,
        bounds.max_event_date
),

behaviour_flags AS (
    SELECT
        user_pseudo_id,

        COUNTIF(
            event_name = 'in_app_purchase'
        ) > 0 AS has_iap,

        COUNTIF(
            event_name = 'ad_reward'
        ) > 0 AS has_ad_reward,

        COUNTIF(
            event_name = 'use_extra_steps'
        ) > 0 AS has_used_extra_steps,

        COUNTIF(
            event_name = 'no_more_extra_steps'
        ) > 0 AS has_no_more_extra_steps,

        COUNTIF(
            event_name = 'in_app_purchase'
            AND EXISTS (
                SELECT 1
                FROM UNNEST(event_params) AS ep
                WHERE ep.key = 'product_id'
                  AND ep.value.string_value LIKE 'extra_steps_pack_%'
            )
        ) > 0 AS has_extra_steps_purchase

    FROM event_enriched

    GROUP BY user_pseudo_id
)

SELECT
    u.user_pseudo_id,
    u.cohort_date,
    u.platform,
    u.install_source,

    fr.result_timestamp AS first_result_timestamp,
    fr.outcome AS first_result_outcome,

    CASE
        WHEN fr.user_pseudo_id IS NULL
            THEN NULL
        ELSE COALESCE(a.is_activated, FALSE)
    END AS is_activated,

    COALESCE(
        fsd.first_session_depth,
        0
    ) AS first_session_depth,

    CASE
        WHEN fr.outcome = 'fail'
            THEN COALESCE(
                rf.retried_after_first_fail,
                FALSE
            )
        ELSE NULL
    END AS retried_after_first_fail,

    COALESCE(
        sdr.same_day_return,
        FALSE
    ) AS same_day_return,

    r.is_d1_observable,
    r.is_d1_retained,
    r.is_d7_observable,
    r.is_d7_retained,

    COALESCE(b.has_iap, FALSE)
        AS has_iap,

    COALESCE(b.has_ad_reward, FALSE)
        AS has_ad_reward,

    COALESCE(b.has_used_extra_steps, FALSE)
        AS has_used_extra_steps,

    COALESCE(b.has_no_more_extra_steps, FALSE)
        AS has_no_more_extra_steps,

    COALESCE(b.has_extra_steps_purchase, FALSE)
        AS has_extra_steps_purchase

FROM `sixth-tempo-506411-d9.floodit_analytics.users` AS u

LEFT JOIN first_result AS fr
    USING (user_pseudo_id)

LEFT JOIN activation AS a
    USING (user_pseudo_id)

LEFT JOIN first_session_depth AS fsd
    USING (user_pseudo_id)

LEFT JOIN retry_after_first_fail AS rf
    USING (user_pseudo_id)

LEFT JOIN same_day_return AS sdr
    USING (user_pseudo_id)

LEFT JOIN retention AS r
    USING (user_pseudo_id)

LEFT JOIN behaviour_flags AS b
    USING (user_pseudo_id);