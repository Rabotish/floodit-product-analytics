ASSERT (
    SELECT COUNT(*) > 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'mart_user_early_journey is empty';


ASSERT (
    SELECT COUNT(*) = COUNT(DISTINCT user_pseudo_id)
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'mart_user_early_journey must contain one row per user';


ASSERT (
    SELECT COUNTIF(user_pseudo_id IS NULL) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'user_pseudo_id contains NULL values';


ASSERT (
    SELECT COUNTIF(cohort_date IS NULL) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'cohort_date contains NULL values';


ASSERT (
    SELECT COUNTIF(platform IS NULL) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'platform contains NULL values';


ASSERT (
    SELECT COUNTIF(
        first_result_timestamp IS NULL
        AND first_result_outcome IS NOT NULL
    ) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'first_result_outcome exists without first_result_timestamp';


ASSERT (
    SELECT COUNTIF(
        first_result_timestamp IS NOT NULL
        AND first_result_outcome IS NULL
    ) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'first_result_timestamp exists without first_result_outcome';


ASSERT (
    SELECT COUNTIF(
        first_result_timestamp IS NULL
        AND is_activated IS NOT NULL
    ) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'activation must be NULL when first result is absent';


ASSERT (
    SELECT COUNTIF(
        first_result_timestamp IS NOT NULL
        AND is_activated IS NULL
    ) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'activation must be defined after first result';


ASSERT (
    SELECT COUNTIF(
        first_result_outcome = 'fail'
        AND retried_after_first_fail IS NULL
    ) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'retry must be defined for users with first fail';


ASSERT (
    SELECT COUNTIF(
        (first_result_outcome IS NULL OR first_result_outcome != 'fail')
        AND retried_after_first_fail IS NOT NULL
    ) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'retry must be NULL for users without first fail';


ASSERT (
    SELECT COUNTIF(is_d1_observable IS NULL) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'is_d1_observable contains NULL values';


ASSERT (
    SELECT COUNTIF(
        is_d1_observable
        AND is_d1_retained IS NULL
    ) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'D1 retention must be defined for observable users';


ASSERT (
    SELECT COUNTIF(
        NOT is_d1_observable
        AND is_d1_retained IS NOT NULL
    ) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'D1 retention must be NULL for non-observable users';


ASSERT (
    SELECT COUNTIF(is_d7_observable IS NULL) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'is_d7_observable contains NULL values';


ASSERT (
    SELECT COUNTIF(
        is_d7_observable
        AND is_d7_retained IS NULL
    ) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'D7 retention must be defined for observable users';


ASSERT (
    SELECT COUNTIF(
        NOT is_d7_observable
        AND is_d7_retained IS NOT NULL
    ) = 0
    FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`
)
AS 'D7 retention must be NULL for non-observable users';