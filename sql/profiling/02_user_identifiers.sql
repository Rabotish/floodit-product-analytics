-- 1. Покрытие пользовательских идентификаторов
SELECT
    COUNT(*) AS event_count,

    COUNT(DISTINCT user_pseudo_id) AS unique_user_pseudo_id,
    COUNTIF(user_pseudo_id IS NULL) AS null_user_pseudo_id,

    COUNT(DISTINCT user_id) AS unique_user_id,
    COUNTIF(user_id IS NULL) AS null_user_id

FROM `firebase-public-project.analytics_153293282.events_*`;


-- 2. Полнота и согласованность user_first_touch_timestamp

WITH users AS (
    SELECT
        user_pseudo_id,

        COUNT(*) AS event_count,

        COUNTIF(
            user_first_touch_timestamp IS NULL
        ) AS null_first_touch_count,

        COUNT(
            DISTINCT user_first_touch_timestamp
        ) AS distinct_first_touch_count

    FROM `firebase-public-project.analytics_153293282.events_*`

    WHERE user_pseudo_id IS NOT NULL

    GROUP BY user_pseudo_id
)

SELECT
    COUNT(*) AS user_count,

    COUNTIF(
        null_first_touch_count = event_count
    ) AS users_without_first_touch,

    COUNTIF(
        null_first_touch_count > 0
        AND null_first_touch_count < event_count
    ) AS users_with_partial_first_touch,

    COUNTIF(
        distinct_first_touch_count = 1
    ) AS users_with_one_first_touch,

    COUNTIF(
        distinct_first_touch_count > 1
    ) AS users_with_multiple_first_touch

FROM users;


-- 3. Количество first_open на пользователя

WITH users AS (
    SELECT
        user_pseudo_id,

        COUNTIF(
            event_name = 'first_open'
        ) AS first_open_count

    FROM `firebase-public-project.analytics_153293282.events_*`

    WHERE user_pseudo_id IS NOT NULL

    GROUP BY user_pseudo_id
)

SELECT
    COUNT(*) AS user_count,

    COUNTIF(
        first_open_count = 0
    ) AS users_without_first_open,

    COUNTIF(
        first_open_count = 1
    ) AS users_with_one_first_open,

    COUNTIF(
        first_open_count > 1
    ) AS users_with_multiple_first_open,

    MAX(first_open_count) AS max_first_open_count

FROM users;

-- 4. Согласованность first_open и user_first_touch_timestamp

WITH users AS (
    SELECT
        user_pseudo_id,

        MIN(
            user_first_touch_timestamp
        ) AS first_touch_timestamp,

        MIN(
            IF(
                event_name = 'first_open',
                event_timestamp,
                NULL
            )
        ) AS first_open_timestamp

    FROM `firebase-public-project.analytics_153293282.events_*`

    WHERE user_pseudo_id IS NOT NULL

    GROUP BY user_pseudo_id
),

comparison AS (
    SELECT
        user_pseudo_id,

        first_touch_timestamp,
        first_open_timestamp,

        TIMESTAMP_DIFF(
            TIMESTAMP_MICROS(first_open_timestamp),
            TIMESTAMP_MICROS(first_touch_timestamp),
            SECOND
        ) AS diff_seconds

    FROM users

    WHERE first_open_timestamp IS NOT NULL
      AND first_touch_timestamp IS NOT NULL
)

SELECT
    COUNT(*) AS compared_users,

    COUNTIF(
        diff_seconds = 0
    ) AS exact_match,

    COUNTIF(
        ABS(diff_seconds) <= 1
    ) AS difference_within_1_second,

    COUNTIF(
        ABS(diff_seconds) <= 60
    ) AS difference_within_1_minute,

    COUNTIF(
        diff_seconds < 0
    ) AS first_open_before_first_touch,

    COUNTIF(
        diff_seconds > 0
    ) AS first_open_after_first_touch,

    MIN(diff_seconds) AS min_diff_seconds,
    MAX(diff_seconds) AS max_diff_seconds

FROM comparison;

-- 5. Первый наблюдаемый event пользователя

WITH users AS (
    SELECT
        user_pseudo_id,

        MIN(event_timestamp) AS first_observed_timestamp,

        MIN(
            IF(
                event_name = 'first_open',
                event_timestamp,
                NULL
            )
        ) AS first_open_timestamp,

        MIN(
            user_first_touch_timestamp
        ) AS first_touch_timestamp

    FROM `firebase-public-project.analytics_153293282.events_*`

    WHERE user_pseudo_id IS NOT NULL

    GROUP BY user_pseudo_id
)

SELECT
    COUNT(*) AS user_count,

    COUNTIF(
        first_open_timestamp IS NOT NULL
    ) AS users_with_first_open,

    COUNTIF(
        first_open_timestamp = first_observed_timestamp
    ) AS first_open_is_first_observed_event,

    COUNTIF(
        first_open_timestamp > first_observed_timestamp
    ) AS events_observed_before_first_open,

    COUNTIF(
        first_touch_timestamp > first_observed_timestamp
    ) AS first_touch_after_first_observed_event

FROM users;