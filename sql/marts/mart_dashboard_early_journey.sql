CREATE OR REPLACE TABLE
    `sixth-tempo-506411-d9.floodit_analytics.mart_dashboard_early_journey` AS

WITH aggregated AS (

    SELECT
        cohort_date,
        platform,

        COALESCE(
            first_result_outcome,
            'no_result'
        ) AS first_result_outcome,

        first_session_depth,

        -- Users in segment
        COUNT(*) AS users,

        -- First observed result
        COUNTIF(
            first_result_outcome IS NOT NULL
        ) AS first_result_users,

        -- Activation
        COUNTIF(
            is_activated IS TRUE
        ) AS activated_users,

        COUNTIF(
            is_activated IS FALSE
        ) AS non_activated_users,

        -- First fail
        COUNTIF(
            first_result_outcome = 'fail'
        ) AS first_fail_users,

        -- Retry after first fail
        COUNTIF(
            retried_after_first_fail IS TRUE
        ) AS retry_users,

        -- Same-day return
        COUNTIF(
            same_day_return IS TRUE
        ) AS same_day_return_users,

        -- D1
        COUNTIF(
            is_d1_observable IS TRUE
        ) AS d1_observable_users,

        COUNTIF(
            is_d1_retained IS TRUE
        ) AS d1_retained_users

    FROM
        `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`

    GROUP BY
        cohort_date,
        platform,
        first_result_outcome,
        first_session_depth
)

SELECT
    cohort_date,
    platform,
    first_result_outcome,
    first_session_depth,

    users,

    first_result_users,

    activated_users,
    non_activated_users,

    SAFE_DIVIDE(
        activated_users,
        first_result_users
    ) AS activation_rate,

    first_fail_users,
    retry_users,

    SAFE_DIVIDE(
        retry_users,
        first_fail_users
    ) AS retry_rate,

    same_day_return_users,

    SAFE_DIVIDE(
        same_day_return_users,
        users
    ) AS same_day_return_rate,

    d1_observable_users,
    d1_retained_users,

    SAFE_DIVIDE(
        d1_retained_users,
        d1_observable_users
    ) AS d1_retention

FROM aggregated;