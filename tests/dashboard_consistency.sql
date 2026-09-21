CREATE TEMP TABLE base AS
SELECT
    COUNT(*) AS users,
    COUNTIF(first_result_timestamp IS NOT NULL) AS first_result_users,
    COUNTIF(is_activated) AS activated_users,

    COUNTIF(is_d1_observable) AS d1_observable_users,
    COUNTIF(is_d1_retained) AS d1_retained_users,

    COUNTIF(is_d7_observable) AS d7_observable_users,
    COUNTIF(is_d7_retained) AS d7_retained_users

FROM `sixth-tempo-506411-d9.floodit_analytics.mart_user_early_journey`;


CREATE TEMP TABLE overview AS
SELECT
    SUM(new_users) AS users,
    SUM(first_result_users) AS first_result_users,
    SUM(activated_users) AS activated_users,

    SUM(d1_observable_users) AS d1_observable_users,
    SUM(d1_retained_users) AS d1_retained_users,

    SUM(d7_observable_users) AS d7_observable_users,
    SUM(d7_retained_users) AS d7_retained_users

FROM `sixth-tempo-506411-d9.floodit_analytics.mart_dashboard_overview`;


CREATE TEMP TABLE early_journey AS
SELECT
    SUM(users) AS users,
    SUM(first_result_users) AS first_result_users,
    SUM(activated_users) AS activated_users

FROM `sixth-tempo-506411-d9.floodit_analytics.mart_dashboard_early_journey`;


CREATE TEMP TABLE retention AS
SELECT
    SUM(users) AS users,

    SUM(d1_observable_users) AS d1_observable_users,
    SUM(d1_retained_users) AS d1_retained_users,

    SUM(d7_observable_users) AS d7_observable_users,
    SUM(d7_retained_users) AS d7_retained_users

FROM `sixth-tempo-506411-d9.floodit_analytics.mart_dashboard_retention`;


ASSERT (
    SELECT
        b.users = o.users
        AND b.first_result_users = o.first_result_users
        AND b.activated_users = o.activated_users
        AND b.d1_observable_users = o.d1_observable_users
        AND b.d1_retained_users = o.d1_retained_users
        AND b.d7_observable_users = o.d7_observable_users
        AND b.d7_retained_users = o.d7_retained_users

    FROM base AS b
    CROSS JOIN overview AS o
)
AS 'mart_dashboard_overview is inconsistent with mart_user_early_journey';


ASSERT (
    SELECT
        b.users = e.users
        AND b.first_result_users = e.first_result_users
        AND b.activated_users = e.activated_users

    FROM base AS b
    CROSS JOIN early_journey AS e
)
AS 'mart_dashboard_early_journey is inconsistent with mart_user_early_journey';


ASSERT (
    SELECT
        b.users = r.users
        AND b.d1_observable_users = r.d1_observable_users
        AND b.d1_retained_users = r.d1_retained_users
        AND b.d7_observable_users = r.d7_observable_users
        AND b.d7_retained_users = r.d7_retained_users

    FROM base AS b
    CROSS JOIN retention AS r
)
AS 'mart_dashboard_retention is inconsistent with mart_user_early_journey';