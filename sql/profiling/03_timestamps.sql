-- 1. Полнота основных временных полей

SELECT
    COUNT(*) AS event_count,

    COUNTIF(event_timestamp IS NULL)
        AS null_event_timestamp,

    COUNTIF(event_previous_timestamp IS NULL)
        AS null_event_previous_timestamp,

    COUNTIF(event_server_timestamp_offset IS NULL)
        AS null_event_server_timestamp_offset,

    COUNTIF(user_first_touch_timestamp IS NULL)
        AS null_user_first_touch_timestamp

FROM `firebase-public-project.analytics_153293282.events_*`;


-- 2. Диапазоны временных меток

SELECT
    MIN(TIMESTAMP_MICROS(event_timestamp))
        AS min_event_timestamp,

    MAX(TIMESTAMP_MICROS(event_timestamp))
        AS max_event_timestamp,

    MIN(TIMESTAMP_MICROS(event_previous_timestamp))
        AS min_event_previous_timestamp,

    MAX(TIMESTAMP_MICROS(event_previous_timestamp))
        AS max_event_previous_timestamp,

    MIN(TIMESTAMP_MICROS(user_first_touch_timestamp))
        AS min_user_first_touch_timestamp,

    MAX(TIMESTAMP_MICROS(user_first_touch_timestamp))
        AS max_user_first_touch_timestamp

FROM `firebase-public-project.analytics_153293282.events_*`;


-- 3. Разница между event_date и UTC-датой event_timestamp

WITH events AS (
    SELECT
        PARSE_DATE('%Y%m%d', event_date) AS event_date,
        DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_timestamp_utc_date
    FROM `firebase-public-project.analytics_153293282.events_*`
)

SELECT
    DATE_DIFF(
        event_timestamp_utc_date,
        event_date,
        DAY
    ) AS date_difference_days,

    COUNT(*) AS event_count

FROM events

GROUP BY date_difference_days
ORDER BY date_difference_days;


-- 4.1. Согласованность event_previous_timestamp

WITH events AS (
    SELECT
        event_timestamp,
        event_previous_timestamp,

        event_timestamp - event_previous_timestamp
            AS difference_micros

    FROM `firebase-public-project.analytics_153293282.events_*`

    WHERE event_previous_timestamp IS NOT NULL
)

SELECT
    COUNT(*) AS events_with_previous_timestamp,

    COUNTIF(
        event_previous_timestamp > event_timestamp
    ) AS previous_timestamp_after_event,

    COUNTIF(
        event_previous_timestamp = event_timestamp
    ) AS previous_timestamp_equals_event,

    COUNTIF(
        event_previous_timestamp < event_timestamp
    ) AS previous_timestamp_before_event,

    MIN(difference_micros) / 1000000.0
        AS min_difference_seconds,

    MAX(difference_micros) / 1000000.0
        AS max_difference_seconds

FROM events;


-- 4.2. Подозрительные значения event_previous_timestamp

SELECT
    COUNTIF(
        event_previous_timestamp IS NOT NULL
        AND TIMESTAMP_MICROS(event_previous_timestamp)
            < TIMESTAMP('2000-01-01')
    ) AS previous_timestamp_before_2000,

    COUNTIF(
        event_previous_timestamp IS NOT NULL
        AND TIMESTAMP_MICROS(event_previous_timestamp)
            > TIMESTAMP('2018-10-04 23:59:59 UTC')
    ) AS previous_timestamp_after_dataset_period

FROM `firebase-public-project.analytics_153293282.events_*`;


-- 5.1. event_server_timestamp_offset

SELECT
    COUNT(*) AS event_count,

    COUNTIF(
        event_server_timestamp_offset IS NULL
    ) AS null_offset,

    COUNTIF(
        event_server_timestamp_offset = 0
    ) AS zero_offset,

    COUNTIF(
        event_server_timestamp_offset < 0
    ) AS negative_offset,

    COUNTIF(
        event_server_timestamp_offset > 0
    ) AS positive_offset,

    MIN(event_server_timestamp_offset) / 1000000.0
        AS min_offset_seconds,

    MAX(event_server_timestamp_offset) / 1000000.0
        AS max_offset_seconds

FROM `firebase-public-project.analytics_153293282.events_*`;


-- 5.2. Распределение event_server_timestamp_offset

SELECT
    APPROX_QUANTILES(
        event_server_timestamp_offset / 1000000.0,
        100
    )[OFFSET(50)] AS median_offset_seconds,

    APPROX_QUANTILES(
        event_server_timestamp_offset / 1000000.0,
        100
    )[OFFSET(90)] AS p90_offset_seconds,

    APPROX_QUANTILES(
        event_server_timestamp_offset / 1000000.0,
        100
    )[OFFSET(95)] AS p95_offset_seconds,

    APPROX_QUANTILES(
        event_server_timestamp_offset / 1000000.0,
        100
    )[OFFSET(99)] AS p99_offset_seconds

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_server_timestamp_offset IS NOT NULL;


-- 6. Распределение user_first_touch_timestamp по пользователям

WITH users AS (
    SELECT
        user_pseudo_id,
        MIN(user_first_touch_timestamp) AS first_touch_timestamp
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE user_pseudo_id IS NOT NULL
    GROUP BY user_pseudo_id
)

SELECT
    COUNT(*) AS user_count,

    COUNTIF(
        TIMESTAMP_MICROS(first_touch_timestamp)
            < TIMESTAMP('2000-01-01')
    ) AS first_touch_before_2000,

    COUNTIF(
        TIMESTAMP_MICROS(first_touch_timestamp)
            < TIMESTAMP('2018-06-12')
    ) AS first_touch_before_dataset,

    COUNTIF(
        TIMESTAMP_MICROS(first_touch_timestamp)
            >= TIMESTAMP('2018-06-12')
        AND
        TIMESTAMP_MICROS(first_touch_timestamp)
            < TIMESTAMP('2018-10-05')
    ) AS first_touch_during_dataset,

    COUNTIF(
        TIMESTAMP_MICROS(first_touch_timestamp)
            >= TIMESTAMP('2018-10-05')
    ) AS first_touch_after_dataset

FROM users;

--6.1. Разница между user_first_touch_timestamp и первым событием пользователя

WITH users AS (
    SELECT
        user_pseudo_id,
        MIN(event_timestamp) AS first_observed_event,
        MIN(user_first_touch_timestamp) AS first_open_time
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE user_pseudo_id IS NOT NULL
    GROUP BY user_pseudo_id
),

new_users AS (
    SELECT
        *,
        (first_observed_event - first_open_time) / 1000000.0
            AS diff_seconds
    FROM users
    WHERE TIMESTAMP_MICROS(first_open_time)
          >= TIMESTAMP('2018-06-12')
      AND TIMESTAMP_MICROS(first_open_time)
          < TIMESTAMP('2018-10-05')
)

SELECT
    COUNT(*) AS candidate_new_users,

    COUNTIF(diff_seconds < 0)
        AS users_with_events_before_first_open,

    COUNTIF(diff_seconds >= -1 AND diff_seconds < 0)
        AS earlier_within_1_second,

    COUNTIF(diff_seconds >= -60 AND diff_seconds < -1)
        AS earlier_1_to_60_seconds,

    COUNTIF(diff_seconds >= -3600 AND diff_seconds < -60)
        AS earlier_1_minute_to_1_hour,

    COUNTIF(diff_seconds >= -86400 AND diff_seconds < -3600)
        AS earlier_1_hour_to_1_day,

    COUNTIF(diff_seconds < -86400)
        AS earlier_more_than_1_day,

    MIN(diff_seconds) AS min_diff_seconds,
    MAX(diff_seconds) AS max_diff_seconds
FROM new_users;

-- 7. Согласованность event_date с календарной датой в timezone приложения

SELECT
    COUNT(*) AS event_count,

    COUNTIF(
        PARSE_DATE('%Y%m%d', event_date)
        = DATE(TIMESTAMP_MICROS(event_timestamp), 'UTC')
    ) AS matches_utc,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(
                PARSE_DATE('%Y%m%d', event_date)
                = DATE(TIMESTAMP_MICROS(event_timestamp), 'UTC')
            ),
            COUNT(*)
        ),
        2
    ) AS matches_utc_pct,

    COUNTIF(
        PARSE_DATE('%Y%m%d', event_date)
        = DATE(
            TIMESTAMP_MICROS(event_timestamp),
            'America/Los_Angeles'
        )
    ) AS matches_los_angeles,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(
                PARSE_DATE('%Y%m%d', event_date)
                = DATE(
                    TIMESTAMP_MICROS(event_timestamp),
                    'America/Los_Angeles'
                )
            ),
            COUNT(*)
        ),
        2
    ) AS matches_los_angeles_pct

FROM `firebase-public-project.analytics_153293282.events_*`;