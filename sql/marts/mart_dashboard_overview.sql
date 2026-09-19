CREATE OR REPLACE TABLE
  `sixth-tempo-506411-d9.floodit_analytics.mart_dashboard_overview` AS

WITH aggregated AS (

    SELECT
        cohort_date,
        platform,

        -- New users
        COUNT(*) AS new_users,

        -- First observed result
        COUNTIF(first_result_outcome IS NOT NULL)
            AS first_result_users,

        COUNTIF(first_result_outcome = 'success')
            AS first_success_users,

        COUNTIF(first_result_outcome = 'fail')
            AS first_fail_users,

        -- Activation
        COUNTIF(is_activated IS TRUE)
            AS activated_users,

        -- Retry after first fail
        COUNTIF(retried_after_first_fail IS TRUE)
            AS retry_users,

        -- Same-day return
        COUNTIF(same_day_return IS TRUE)
            AS same_day_return_users,

        -- D1
        COUNTIF(is_d1_observable IS TRUE)
            AS d1_observable_users,

        COUNTIF(is_d1_retained IS TRUE)
            AS d1_retained_users,

        -- D7
        COUNTIF(is_d7_observable IS TRUE)
            AS d7_observable_users,

        COUNTIF(is_d7_retained IS TRUE)
            AS d7_retained_users,

        -- IAP
        COUNTIF(has_iap IS TRUE)
            AS iap_users

    FROM
        `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`

    GROUP BY
        cohort_date,
        platform
)

SELECT
    cohort_date,
    platform,

    new_users,

    first_result_users,
    first_success_users,
    first_fail_users,

    SAFE_DIVIDE(
        first_result_users,
        new_users
    ) AS first_result_rate,

    activated_users,

    SAFE_DIVIDE(
        activated_users,
        first_result_users
    ) AS activation_rate,

    retry_users,

    SAFE_DIVIDE(
        retry_users,
        first_fail_users
    ) AS retry_rate,

    same_day_return_users,

    SAFE_DIVIDE(
        same_day_return_users,
        new_users
    ) AS same_day_return_rate,

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
    ) AS d7_retention,

    iap_users,

    SAFE_DIVIDE(
        iap_users,
        new_users
    ) AS iap_rate

FROM aggregated;