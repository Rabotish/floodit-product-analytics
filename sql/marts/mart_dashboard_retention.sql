CREATE OR REPLACE TABLE
    `sixth-tempo-506411-d9.floodit_analytics.mart_dashboard_retention` AS

WITH aggregated AS (

    SELECT
        cohort_date,
        platform,

        COALESCE(
            first_result_outcome,
            'no_result'
        ) AS first_result_outcome,

        CASE
            WHEN is_activated IS TRUE
                THEN 'activated'

            WHEN is_activated IS FALSE
                THEN 'not_activated'

            ELSE 'not_applicable'
        END AS activation_status,

        same_day_return,

        first_session_depth,

        COUNT(*) AS users,

        -- D1
        COUNTIF(
            is_d1_observable IS TRUE
        ) AS d1_observable_users,

        COUNTIF(
            is_d1_retained IS TRUE
        ) AS d1_retained_users,

        -- D7
        COUNTIF(
            is_d7_observable IS TRUE
        ) AS d7_observable_users,

        COUNTIF(
            is_d7_retained IS TRUE
        ) AS d7_retained_users

    FROM
        `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`

    GROUP BY
        cohort_date,
        platform,
        first_result_outcome,
        activation_status,
        same_day_return,
        first_session_depth
)

SELECT
    cohort_date,
    platform,
    first_result_outcome,
    activation_status,
    same_day_return,
    first_session_depth,

    users,

    d1_observable_users,
    d1_retained_users,

    SAFE_DIVIDE(
        d1_retained_users,
        d1_observable_users
    ) AS d1_retention,

    d7_observable_users,
    d7_retained_users,

    SAFE_DIVIDE(
        d7_retained_users,
        d7_observable_users
    ) AS d7_retention

FROM aggregated;