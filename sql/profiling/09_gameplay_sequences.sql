-- 1. Однозначность порядка gameplay events

WITH gameplay AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',
        'level_up',
        'post_score',

        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

timestamp_groups AS (
    SELECT
        user_pseudo_id,
        event_timestamp,

        COUNT(*) AS event_count,
        COUNT(DISTINCT event_name) AS distinct_event_names

    FROM gameplay

    GROUP BY
        user_pseudo_id,
        event_timestamp
)

SELECT
    COUNT(*) AS timestamp_groups,

    COUNTIF(event_count > 1)
        AS groups_with_multiple_events,

    COUNTIF(
        event_count > 1
        AND distinct_event_names > 1
    ) AS groups_with_different_events,

    SUM(
        IF(event_count > 1, event_count, 0)
    ) AS events_in_non_unique_timestamps,

    MAX(event_count)
        AS max_events_same_timestamp

FROM timestamp_groups;


-- 2. Неоднозначность порядка после удаления полных дубликатов и возможность использовать event_bundle_sequence_id

WITH deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id

    FROM deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',
        'level_up',
        'post_score',

        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

timestamp_groups AS (
    SELECT
        user_pseudo_id,
        event_timestamp,

        COUNT(*) AS event_count,
        COUNT(DISTINCT event_name) AS distinct_event_names,
        COUNT(DISTINCT event_bundle_sequence_id) AS distinct_bundle_ids,
        COUNTIF(event_bundle_sequence_id IS NULL) AS null_bundle_ids

    FROM gameplay

    GROUP BY
        user_pseudo_id,
        event_timestamp

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS collision_groups,

    SUM(event_count) AS events_in_collision_groups,

    COUNTIF(distinct_event_names > 1)
        AS groups_with_different_events,

    COUNTIF(
        null_bundle_ids = 0
        AND distinct_bundle_ids = event_count
    ) AS groups_resolved_by_bundle_id,

    COUNTIF(
        distinct_bundle_ids < event_count
        OR null_bundle_ids > 0
    ) AS groups_not_resolved_by_bundle_id,

    MAX(event_count) AS max_events_same_timestamp

FROM timestamp_groups;


-- 3. Типы gameplay-событий с одинаковым timestamp

WITH deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id

    FROM deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',
        'level_up',
        'post_score',

        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

collisions AS (
    SELECT
        user_pseudo_id,
        event_timestamp,

        ARRAY_AGG(
            STRUCT(
                event_name,
                event_bundle_sequence_id
            )
            ORDER BY event_bundle_sequence_id, event_name
        ) AS events

    FROM gameplay

    GROUP BY
        user_pseudo_id,
        event_timestamp

    HAVING COUNT(*) > 1
)

SELECT
    events[OFFSET(0)].event_name AS event_1,
    events[OFFSET(1)].event_name AS event_2,

    COUNT(*) AS group_count,

    COUNTIF(
        events[OFFSET(0)].event_bundle_sequence_id
        != events[OFFSET(1)].event_bundle_sequence_id
    ) AS different_bundle_ids

FROM collisions

GROUP BY
    event_1,
    event_2

ORDER BY
    group_count DESC,
    event_1,
    event_2;


-- 4. Содержимое gameplay-событий с одинаковым timestamp

WITH deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,
        event_previous_timestamp,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level,

        (
            SELECT ANY_VALUE(p.value.string_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'board'
        ) AS board,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'score'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'score'
                ) AS INT64
            )
        ) AS score

    FROM deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',
        'level_up',
        'post_score',
        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

collision_keys AS (
    SELECT
        user_pseudo_id,
        event_timestamp
    FROM gameplay
    GROUP BY
        user_pseudo_id,
        event_timestamp
    HAVING COUNT(*) > 1
)

SELECT
    g.user_pseudo_id,
    TIMESTAMP_MICROS(g.event_timestamp) AS event_time,
    g.event_name,
    g.level,
    g.board,
    g.score,
    g.event_bundle_sequence_id,
    TIMESTAMP_MICROS(g.event_previous_timestamp)
        AS previous_event_time

FROM gameplay AS g

JOIN collision_keys AS c
    USING (user_pseudo_id, event_timestamp)

ORDER BY
    g.user_pseudo_id,
    g.event_timestamp,
    g.event_name;


-- 4.1. Совпадает ли level у разных событий одного timestamp

WITH deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level

    FROM deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',
        'level_up',
        'post_score'
    )
),

collisions AS (
    SELECT
        user_pseudo_id,
        event_timestamp,

        COUNT(*) AS event_count,
        COUNT(DISTINCT event_name) AS event_names,

        COUNT(DISTINCT level) AS distinct_levels,
        COUNTIF(level IS NULL) AS null_levels,

        STRING_AGG(
            CONCAT(
                event_name,
                ':',
                COALESCE(CAST(level AS STRING), 'NULL')
            ),
            ', '
            ORDER BY event_name
        ) AS events

    FROM gameplay

    GROUP BY
        user_pseudo_id,
        event_timestamp

    HAVING COUNT(*) > 1
       AND COUNT(DISTINCT event_name) > 1
)

SELECT
    event_count,
    distinct_levels,
    null_levels,
    COUNT(*) AS collision_groups
FROM collisions
GROUP BY
    event_count,
    distinct_levels,
    null_levels
ORDER BY
    collision_groups DESC;

-- 4.2. Различаются ли параметры одинаковых событий с одинаковым timestamp

WITH deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level,

        (
            SELECT ANY_VALUE(p.value.string_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'board'
        ) AS board

    FROM deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',
        'level_up',
        'post_score',
        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

collisions AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,

        COUNT(*) AS event_count,
        COUNT(DISTINCT level) AS distinct_levels,
        COUNT(DISTINCT board) AS distinct_boards

    FROM gameplay

    GROUP BY
        user_pseudo_id,
        event_timestamp,
        event_name

    HAVING COUNT(*) > 1
)

SELECT
    event_name,
    COUNT(*) AS collision_groups,

    COUNTIF(distinct_levels > 1)
        AS groups_with_different_levels,

    COUNTIF(distinct_boards > 1)
        AS groups_with_different_boards

FROM collisions

GROUP BY event_name
ORDER BY collision_groups DESC;


-- 5. Различия внутри одинаковых gameplay-событий с одинаковым timestamp

WITH deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,
        event_previous_timestamp,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level,

        (
            SELECT ANY_VALUE(p.value.string_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'board'
        ) AS board,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'score'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'score'
                ) AS INT64
            )
        ) AS score,

        -- порядок элементов массива не должен создавать ложное различие.
        (
            SELECT STRING_AGG(
                TO_JSON_STRING(p),
                '|' ORDER BY p.key
            )
            FROM UNNEST(event_params) AS p
        ) AS event_params_canonical,

        (
            SELECT STRING_AGG(
                TO_JSON_STRING(p),
                '|' ORDER BY p.key
            )
            FROM UNNEST(user_properties) AS p
        ) AS user_properties_canonical

    FROM deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',
        'level_up',
        'post_score',
        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

collisions AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,

        COUNT(*) AS event_count,

        COUNT(DISTINCT level) AS distinct_levels,
        COUNT(DISTINCT board) AS distinct_boards,
        COUNT(DISTINCT score) AS distinct_scores,

        COUNT(DISTINCT event_bundle_sequence_id)
            AS distinct_bundle_ids,

        COUNT(DISTINCT event_previous_timestamp)
            AS distinct_previous_timestamps,

        COUNT(DISTINCT event_params_canonical)
            AS distinct_event_params,

        COUNT(DISTINCT user_properties_canonical)
            AS distinct_user_properties

    FROM gameplay

    GROUP BY
        user_pseudo_id,
        event_timestamp,
        event_name

    HAVING COUNT(*) > 1
)

SELECT
    event_name,
    COUNT(*) AS collision_groups,

    COUNTIF(distinct_levels > 1)
        AS different_level,

    COUNTIF(distinct_boards > 1)
        AS different_board,

    COUNTIF(distinct_scores > 1)
        AS different_score,

    COUNTIF(distinct_bundle_ids > 1)
        AS different_bundle_id,

    COUNTIF(distinct_previous_timestamps > 1)
        AS different_previous_timestamp,

    COUNTIF(distinct_event_params > 1)
        AS different_event_params,

    COUNTIF(distinct_user_properties > 1)
        AS different_user_properties

FROM collisions

GROUP BY event_name
ORDER BY collision_groups DESC;


-- 6. Источник различий одинаковых gameplay events

WITH deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay AS (
    SELECT
        e.user_pseudo_id,
        e.event_timestamp,
        e.event_name,

        -- Все top-level поля, кроме двух repeated-массивов
        TO_JSON_STRING(
            (
                SELECT AS STRUCT
                    e.* EXCEPT(event_params, user_properties)
            )
        ) AS top_level_fields,

        -- Массивы в исходном порядке
        TO_JSON_STRING(e.event_params)
            AS event_params_raw,

        TO_JSON_STRING(e.user_properties)
            AS user_properties_raw,

        -- Те же массивы после канонической сортировки
        (
            SELECT STRING_AGG(
                TO_JSON_STRING(p),
                '|' ORDER BY p.key
            )
            FROM UNNEST(e.event_params) AS p
        ) AS event_params_canonical,

        (
            SELECT STRING_AGG(
                TO_JSON_STRING(p),
                '|' ORDER BY p.key
            )
            FROM UNNEST(e.user_properties) AS p
        ) AS user_properties_canonical

    FROM deduplicated AS e

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',
        'level_up',
        'post_score',
        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

collisions AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,

        COUNT(*) AS event_count,

        COUNT(DISTINCT top_level_fields)
            AS top_level_variants,

        COUNT(DISTINCT event_params_raw)
            AS raw_event_params_variants,

        COUNT(DISTINCT event_params_canonical)
            AS canonical_event_params_variants,

        COUNT(DISTINCT user_properties_raw)
            AS raw_user_properties_variants,

        COUNT(DISTINCT user_properties_canonical)
            AS canonical_user_properties_variants

    FROM gameplay

    GROUP BY
        user_pseudo_id,
        event_timestamp,
        event_name

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS collision_groups,

    COUNTIF(top_level_variants > 1)
        AS groups_with_top_level_difference,

    COUNTIF(
        raw_event_params_variants > 1
        AND canonical_event_params_variants = 1
    ) AS groups_with_only_event_params_order_difference,

    COUNTIF(
        raw_user_properties_variants > 1
        AND canonical_user_properties_variants = 1
    ) AS groups_with_only_user_properties_order_difference,

    COUNTIF(
        canonical_event_params_variants > 1
    ) AS groups_with_real_event_params_difference,

    COUNTIF(
        canonical_user_properties_variants > 1
    ) AS groups_with_real_user_properties_difference

FROM collisions;


-- 7. Какие top-level поля различаются у одинаковых gameplay-событий с одинаковым timestamp

WITH deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay AS (
    SELECT
        e.user_pseudo_id,
        e.event_timestamp,
        e.event_name,

        e.event_date,
        e.event_previous_timestamp,
        e.event_server_timestamp_offset,
        e.event_value_in_usd,
        e.event_bundle_sequence_id,

        e.user_first_touch_timestamp,
        e.user_id,

        e.platform,
        e.stream_id,

        TO_JSON_STRING(e.app_info) AS app_info,
        TO_JSON_STRING(e.device) AS device,
        TO_JSON_STRING(e.geo) AS geo,
        TO_JSON_STRING(e.traffic_source) AS traffic_source,
        TO_JSON_STRING(e.user_ltv) AS user_ltv,
        TO_JSON_STRING(e.event_dimensions) AS event_dimensions

    FROM deduplicated AS e

    WHERE e.event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',
        'level_up',
        'post_score',
        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

collision_groups AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,

        ARRAY_AGG(
            STRUCT(
                event_date,
                event_previous_timestamp,
                event_server_timestamp_offset,
                event_value_in_usd,
                event_bundle_sequence_id,
                user_first_touch_timestamp,
                user_id,
                platform,
                stream_id,
                app_info,
                device,
                geo,
                traffic_source,
                user_ltv,
                event_dimensions
            )
        ) AS group_rows

    FROM gameplay

    GROUP BY
        user_pseudo_id,
        event_timestamp,
        event_name

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS collision_groups,

    COUNTIF(
        group_rows[OFFSET(0)].event_date
        IS DISTINCT FROM group_rows[OFFSET(1)].event_date
    ) AS different_event_date,

    COUNTIF(
        group_rows[OFFSET(0)].event_previous_timestamp
        IS DISTINCT FROM group_rows[OFFSET(1)].event_previous_timestamp
    ) AS different_previous_timestamp,

    COUNTIF(
        group_rows[OFFSET(0)].event_server_timestamp_offset
        IS DISTINCT FROM group_rows[OFFSET(1)].event_server_timestamp_offset
    ) AS different_server_offset,

    COUNTIF(
        group_rows[OFFSET(0)].event_value_in_usd
        IS DISTINCT FROM group_rows[OFFSET(1)].event_value_in_usd
    ) AS different_event_value_usd,

    COUNTIF(
        group_rows[OFFSET(0)].event_bundle_sequence_id
        IS DISTINCT FROM group_rows[OFFSET(1)].event_bundle_sequence_id
    ) AS different_bundle_id,

    COUNTIF(
        group_rows[OFFSET(0)].user_first_touch_timestamp
        IS DISTINCT FROM group_rows[OFFSET(1)].user_first_touch_timestamp
    ) AS different_first_touch,

    COUNTIF(
        group_rows[OFFSET(0)].user_id
        IS DISTINCT FROM group_rows[OFFSET(1)].user_id
    ) AS different_user_id,

    COUNTIF(
        group_rows[OFFSET(0)].platform
        IS DISTINCT FROM group_rows[OFFSET(1)].platform
    ) AS different_platform,

    COUNTIF(
        group_rows[OFFSET(0)].stream_id
        IS DISTINCT FROM group_rows[OFFSET(1)].stream_id
    ) AS different_stream_id,

    COUNTIF(
        group_rows[OFFSET(0)].app_info
        IS DISTINCT FROM group_rows[OFFSET(1)].app_info
    ) AS different_app_info,

    COUNTIF(
        group_rows[OFFSET(0)].device
        IS DISTINCT FROM group_rows[OFFSET(1)].device
    ) AS different_device,

    COUNTIF(
        group_rows[OFFSET(0)].geo
        IS DISTINCT FROM group_rows[OFFSET(1)].geo
    ) AS different_geo,

    COUNTIF(
        group_rows[OFFSET(0)].traffic_source
        IS DISTINCT FROM group_rows[OFFSET(1)].traffic_source
    ) AS different_traffic_source,

    COUNTIF(
        group_rows[OFFSET(0)].user_ltv
        IS DISTINCT FROM group_rows[OFFSET(1)].user_ltv
    ) AS different_user_ltv,

    COUNTIF(
        group_rows[OFFSET(0)].event_dimensions
        IS DISTINCT FROM group_rows[OFFSET(1)].event_dimensions
    ) AS different_event_dimensions

FROM collision_groups;


-- 8. Следующее gameplay-control событие после start

WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

control_events_raw AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,

        CASE
            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN 'quickplay'
            ELSE 'progressive'
        END AS game_mode,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level,

        (
            SELECT ANY_VALUE(p.value.string_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'board'
        ) AS board

    FROM exact_deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',

        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

-- Подтвержденные logical gameplay duplicates: одинаковые user + timestamp + event_name схлопываем.
control_events AS (
    SELECT *
    FROM control_events_raw

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            user_pseudo_id,
            event_timestamp,
            event_name
        ORDER BY
            event_bundle_sequence_id
    ) = 1
),

sequenced AS (
    SELECT
        *,

        LEAD(event_name) OVER w
            AS next_event_name,

        LEAD(game_mode) OVER w
            AS next_game_mode,

        LEAD(level) OVER w
            AS next_level,

        LEAD(board) OVER w
            AS next_board,

        LEAD(event_timestamp) OVER w
            AS next_event_timestamp

    FROM control_events

    WINDOW w AS (
        PARTITION BY user_pseudo_id
        ORDER BY
            event_timestamp,
            event_bundle_sequence_id,
            event_name
    )
),

starts AS (
    SELECT
        *,

        CASE
            WHEN next_event_name IS NULL
                THEN 'no_next_event'

            WHEN game_mode != next_game_mode
                THEN 'mode_changed'

            WHEN game_mode = 'progressive'
                 AND (level IS NULL OR next_level IS NULL)
                THEN 'level_missing'

            WHEN game_mode = 'progressive'
                 AND level = next_level
                THEN 'same_level'

            WHEN game_mode = 'progressive'
                 AND level != next_level
                THEN 'different_level'

            WHEN game_mode = 'quickplay'
                 AND (board IS NULL OR next_board IS NULL)
                THEN 'board_missing'

            WHEN game_mode = 'quickplay'
                 AND board = next_board
                THEN 'same_board'

            WHEN game_mode = 'quickplay'
                 AND board != next_board
                THEN 'different_board'
        END AS target_relation,

        SAFE_DIVIDE(
            next_event_timestamp - event_timestamp,
            1000000
        ) AS seconds_to_next_event

    FROM sequenced

    WHERE event_name IN (
        'level_start',
        'level_start_quickplay'
    )
)

SELECT
    event_name AS start_event,
    COALESCE(next_event_name, 'NULL') AS next_event,
    target_relation,

    COUNT(*) AS start_count,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNT(*),
            SUM(COUNT(*)) OVER (
                PARTITION BY event_name
            )
        ),
        2
    ) AS share_of_starts_pct,

    APPROX_QUANTILES(
        seconds_to_next_event,
        100
    )[OFFSET(50)] AS median_seconds_to_next,

    APPROX_QUANTILES(
        seconds_to_next_event,
        100
    )[OFFSET(90)] AS p90_seconds_to_next

FROM starts

GROUP BY
    start_event,
    next_event,
    target_relation

ORDER BY
    start_event,
    start_count DESC;


-- 9. Разница level между level_start и следующим progressive control event

WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

control_events_raw AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,

        CASE
            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN 'quickplay'
            ELSE 'progressive'
        END AS game_mode,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level

    FROM exact_deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',

        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

control_events AS (
    SELECT *
    FROM control_events_raw

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            user_pseudo_id,
            event_timestamp,
            event_name
        ORDER BY event_bundle_sequence_id
    ) = 1
),

sequenced AS (
    SELECT
        *,

        LEAD(event_name) OVER w AS next_event_name,
        LEAD(game_mode) OVER w AS next_game_mode,
        LEAD(level) OVER w AS next_level

    FROM control_events

    WINDOW w AS (
        PARTITION BY user_pseudo_id
        ORDER BY
            event_timestamp,
            event_bundle_sequence_id,
            event_name
    )
),

transitions AS (
    SELECT
        next_event_name,
        level,
        next_level,
        next_level - level AS level_delta

    FROM sequenced

    WHERE event_name = 'level_start'
      AND next_game_mode = 'progressive'
      AND level IS NOT NULL
      AND next_level IS NOT NULL
      AND level != next_level
)

SELECT
    next_event_name,

    COUNT(*) AS different_level_transitions,

    COUNTIF(level_delta = 1) AS delta_plus_1,
    COUNTIF(level_delta = -1) AS delta_minus_1,

    COUNTIF(ABS(level_delta) = 1) AS abs_delta_1,
    COUNTIF(ABS(level_delta) > 1) AS abs_delta_gt_1,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(ABS(level_delta) = 1),
            COUNT(*)
        ),
        2
    ) AS share_abs_delta_1_pct,

    MIN(level_delta) AS min_delta,
    APPROX_QUANTILES(level_delta, 100)[OFFSET(50)]
        AS median_delta,
    MAX(level_delta) AS max_delta

FROM transitions

GROUP BY next_event_name

ORDER BY different_level_transitions DESC;

-- 10.  Проверка гипотезы: start N -> level_up N -> start N+1

WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay_raw AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,

        CASE
            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN 'quickplay'
            ELSE 'progressive'
        END AS game_mode,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level

    FROM exact_deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',
        'level_up',

        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

gameplay AS (
    SELECT *
    FROM gameplay_raw

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            user_pseudo_id,
            event_timestamp,
            event_name
        ORDER BY event_bundle_sequence_id
    ) = 1
),

control_events AS (
    SELECT *
    FROM gameplay
    WHERE event_name != 'level_up'
),

sequenced AS (
    SELECT
        *,

        LEAD(event_timestamp) OVER w AS next_timestamp,
        LEAD(event_name) OVER w AS next_event,
        LEAD(game_mode) OVER w AS next_mode,
        LEAD(level) OVER w AS next_level

    FROM control_events

    WINDOW w AS (
        PARTITION BY user_pseudo_id
        ORDER BY
            event_timestamp,
            event_bundle_sequence_id,
            event_name
    )
),

start_to_next_level AS (
    SELECT *
    FROM sequenced

    WHERE event_name = 'level_start'
      AND next_event = 'level_start'
      AND next_mode = 'progressive'
      AND level IS NOT NULL
      AND next_level = level + 1
),

level_ups AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        level
    FROM gameplay
    WHERE event_name = 'level_up'
),

checked AS (
    SELECT
        s.user_pseudo_id,
        s.event_timestamp,
        s.level,
        s.next_timestamp,
        s.next_level,

        COUNTIF(u.event_timestamp IS NOT NULL)
            AS level_ups_between,

        COUNTIF(u.level = s.level)
            AS level_up_start_level,

        COUNTIF(u.level = s.next_level)
            AS level_up_next_level

    FROM start_to_next_level AS s

    LEFT JOIN level_ups AS u
        ON s.user_pseudo_id = u.user_pseudo_id
       AND u.event_timestamp > s.event_timestamp
       AND u.event_timestamp <= s.next_timestamp

    GROUP BY
        s.user_pseudo_id,
        s.event_timestamp,
        s.level,
        s.next_timestamp,
        s.next_level
)

SELECT
    COUNT(*) AS start_n_to_start_n_plus_1,

    COUNTIF(level_ups_between > 0)
        AS with_level_up_between,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(level_ups_between > 0),
            COUNT(*)
        ),
        2
    ) AS share_with_level_up_pct,

    COUNTIF(level_up_start_level > 0)
        AS level_up_matches_start_level,

    COUNTIF(level_up_next_level > 0)
        AS level_up_matches_next_level

FROM checked;


-- 11. Что непосредственно предшествует level_start и с какой временной задержкой

WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

control_events_raw AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level

    FROM exact_deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',

        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

control_events AS (
    SELECT *
    FROM control_events_raw

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            user_pseudo_id,
            event_timestamp,
            event_name
        ORDER BY event_bundle_sequence_id
    ) = 1
),

sequenced AS (
    SELECT
        *,

        LAG(event_name) OVER w AS previous_event_name,
        LAG(level) OVER w AS previous_level,
        LAG(event_timestamp) OVER w AS previous_timestamp

    FROM control_events

    WINDOW w AS (
        PARTITION BY user_pseudo_id
        ORDER BY
            event_timestamp,
            event_bundle_sequence_id,
            event_name
    )
)

SELECT
    COALESCE(previous_event_name, 'NULL') AS previous_event,

    CASE
        WHEN previous_event_name IS NULL
            THEN 'no_previous_event'

        WHEN previous_level IS NULL
            THEN 'level_missing'

        WHEN previous_level = level
            THEN 'same_level'

        WHEN previous_level = level - 1
            THEN 'previous_level_is_N_minus_1'

        WHEN previous_level = level + 1
            THEN 'previous_level_is_N_plus_1'

        ELSE 'other_level'
    END AS level_relation,

    COUNT(*) AS start_count,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNT(*),
            SUM(COUNT(*)) OVER ()
        ),
        2
    ) AS share_pct,

    APPROX_QUANTILES(
        SAFE_DIVIDE(
            event_timestamp - previous_timestamp,
            1000000
        ),
        100
    )[OFFSET(50)] AS median_seconds_from_previous

FROM sequenced

WHERE event_name = 'level_start'

GROUP BY
    previous_event,
    level_relation

ORDER BY start_count DESC;


-- 12 Проверка гипотезы задержки логирования на Android и iOS

WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

control_events_raw AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,
        platform,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level

    FROM exact_deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',

        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

control_events AS (
    SELECT *
    FROM control_events_raw

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            user_pseudo_id,
            event_timestamp,
            event_name
        ORDER BY event_bundle_sequence_id
    ) = 1
),

sequenced AS (
    SELECT
        *,

        LEAD(event_name) OVER w
            AS next_event_name,

        LEAD(level) OVER w
            AS next_level,

        LEAD(platform) OVER w
            AS next_platform

    FROM control_events

    WINDOW w AS (
        PARTITION BY user_pseudo_id
        ORDER BY
            event_timestamp,
            event_bundle_sequence_id,
            event_name
    )
)

SELECT
    platform,
    next_event_name,

    COUNT(*) AS transitions,

    COUNTIF(next_level = level)
        AS same_level,

    COUNTIF(next_level = level - 1)
        AS delta_minus_1,

    COUNTIF(next_level = level + 1)
        AS delta_plus_1,

    COUNTIF(
        next_level IS NOT NULL
        AND ABS(next_level - level) > 1
    ) AS other_delta

FROM sequenced

WHERE event_name = 'level_start'
  AND next_event_name IN (
      'level_complete',
      'level_end'
  )
  AND level IS NOT NULL
  AND next_level IS NOT NULL
  AND platform = next_platform

GROUP BY
    platform,
    next_event_name

ORDER BY
    platform,
    next_event_name;



-- 13. Можно ли связать запоздалый complete/end N-1 с более ранним start N-1


WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

control_events_raw AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,

        CASE
            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN 'quickplay'
            ELSE 'progressive'
        END AS game_mode,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level

    FROM exact_deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',

        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

control_events AS (
    SELECT *
    FROM control_events_raw

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            user_pseudo_id,
            event_timestamp,
            event_name
        ORDER BY event_bundle_sequence_id
    ) = 1
),

sequenced AS (
    SELECT
        *,

        LEAD(event_timestamp) OVER w AS next_timestamp,
        LEAD(event_name) OVER w AS next_event,
        LEAD(game_mode) OVER w AS next_mode,
        LEAD(level) OVER w AS next_level

    FROM control_events

    WINDOW w AS (
        PARTITION BY user_pseudo_id
        ORDER BY
            event_timestamp,
            event_bundle_sequence_id,
            event_name
    )
),

suspicious_transitions AS (
    SELECT
        user_pseudo_id,

        event_timestamp AS new_level_start_timestamp,
        level AS new_level,

        next_timestamp AS terminal_timestamp,
        next_event AS terminal_event,
        next_level AS terminal_level

    FROM sequenced

    WHERE event_name = 'level_start'
      AND game_mode = 'progressive'
      AND next_mode = 'progressive'
      AND next_event IN (
          'level_complete',
          'level_end'
      )
      AND level IS NOT NULL
      AND next_level = level - 1
),

previous_level_starts AS (
    SELECT
        p.*,

        MAX(s.event_timestamp) AS previous_level_start_timestamp

    FROM suspicious_transitions AS p

    LEFT JOIN control_events AS s
        ON p.user_pseudo_id = s.user_pseudo_id
       AND s.event_name = 'level_start'
       AND s.game_mode = 'progressive'
       AND s.level = p.terminal_level
       AND s.event_timestamp < p.new_level_start_timestamp

    GROUP BY
        p.user_pseudo_id,
        p.new_level_start_timestamp,
        p.new_level,
        p.terminal_timestamp,
        p.terminal_event,
        p.terminal_level
)

SELECT
    terminal_event,

    COUNT(*) AS suspicious_transitions,

    COUNTIF(
        previous_level_start_timestamp IS NOT NULL
    ) AS with_previous_level_start,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(previous_level_start_timestamp IS NOT NULL),
            COUNT(*)
        ),
        2
    ) AS share_with_previous_level_start_pct,

    APPROX_QUANTILES(
        SAFE_DIVIDE(
            terminal_timestamp - new_level_start_timestamp,
            1000000
        ),
        100
    )[OFFSET(50)] AS median_seconds_terminal_after_new_start,

    APPROX_QUANTILES(
        IF(
            previous_level_start_timestamp IS NOT NULL,
            SAFE_DIVIDE(
                terminal_timestamp - previous_level_start_timestamp,
                1000000
            ),
            NULL
        ),
        100
    )[OFFSET(50)] AS median_seconds_from_old_start_to_terminal,

    APPROX_QUANTILES(
        IF(
            previous_level_start_timestamp IS NOT NULL,
            SAFE_DIVIDE(
                terminal_timestamp - previous_level_start_timestamp,
                1000000
            ),
            NULL
        ),
        100
    )[OFFSET(90)] AS p90_seconds_from_old_start_to_terminal

FROM previous_level_starts

GROUP BY terminal_event

ORDER BY terminal_event;


-- 14. Повторные start-события с учётом границ session_start


WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay_raw AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,

        CASE
            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN 'quickplay'
            ELSE 'progressive'
        END AS game_mode,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level,

        (
            SELECT ANY_VALUE(p.value.string_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'board'
        ) AS board

    FROM exact_deduplicated

    WHERE event_name IN (
        'level_start',
        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',

        'level_start_quickplay',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
),

-- Схлопываем уже подтверждённые logical gameplay duplicates.
gameplay AS (
    SELECT *
    FROM gameplay_raw

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            user_pseudo_id,
            event_timestamp,
            event_name
        ORDER BY event_bundle_sequence_id
    ) = 1
),

session_boundaries AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,

        CAST(NULL AS STRING) AS game_mode,
        CAST(NULL AS INT64) AS level,
        CAST(NULL AS STRING) AS board

    FROM exact_deduplicated

    WHERE event_name = 'session_start'
),

event_stream AS (
    SELECT * FROM gameplay

    UNION ALL

    SELECT * FROM session_boundaries
),

prepared AS (
    SELECT
        *,

        CASE
            WHEN game_mode = 'progressive'
                THEN CAST(level AS STRING)
            WHEN game_mode = 'quickplay'
                THEN board
        END AS game_key,

        CASE
            WHEN event_name IN (
                'level_start',
                'level_start_quickplay'
            )
                THEN 1
            ELSE 0
        END AS is_start,

        -- session_start ставим раньше gameplay event,
        -- если timestamp вдруг совпадает.
        CASE
            WHEN event_name = 'session_start' THEN 0
            ELSE 1
        END AS event_priority

    FROM event_stream
),

ordered AS (
    SELECT
        *,

        LAG(event_name) OVER w
            AS previous_event_name,

        LAG(game_mode) OVER w
            AS previous_game_mode,

        LAG(game_key) OVER w
            AS previous_game_key

    FROM prepared

    WINDOW w AS (
        PARTITION BY user_pseudo_id
        ORDER BY
            event_timestamp,
            event_priority,
            event_bundle_sequence_id,
            event_name
    )
),

marked AS (
    SELECT
        *,

        CASE
            WHEN is_start = 1
             AND previous_event_name IN (
                 'level_start',
                 'level_start_quickplay'
             )
             AND game_mode = previous_game_mode
             AND game_key = previous_game_key
                THEN 0
            ELSE 1
        END AS new_sequence_flag

    FROM ordered
),

numbered AS (
    SELECT
        *,

        SUM(new_sequence_flag) OVER (
            PARTITION BY user_pseudo_id
            ORDER BY
                event_timestamp,
                event_priority,
                event_bundle_sequence_id,
                event_name
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS sequence_id

    FROM marked
),

start_clusters AS (
    SELECT
        user_pseudo_id,
        game_mode,
        game_key,
        sequence_id,

        COUNT(*) AS start_count,

        MIN(event_timestamp) AS first_start_timestamp,
        MAX(event_timestamp) AS last_start_timestamp

    FROM numbered

    WHERE is_start = 1

    GROUP BY
        user_pseudo_id,
        game_mode,
        game_key,
        sequence_id
),

with_duration AS (
    SELECT
        *,

        SAFE_DIVIDE(
            last_start_timestamp - first_start_timestamp,
            1000000
        ) AS cluster_span_seconds

    FROM start_clusters
)

SELECT
    game_mode,

    COUNT(*) AS start_clusters,

    SUM(start_count) AS start_events,

    COUNTIF(start_count > 1)
        AS repeated_start_clusters,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(start_count > 1),
            COUNT(*)
        ),
        2
    ) AS repeated_cluster_share_pct,

    SUM(
        IF(start_count > 1, start_count - 1, 0)
    ) AS additional_starts_in_repeated_clusters,

    COUNTIF(start_count = 2)
        AS clusters_with_2_starts,

    COUNTIF(start_count = 3)
        AS clusters_with_3_starts,

    COUNTIF(start_count >= 4)
        AS clusters_with_4plus_starts,

    MAX(start_count)
        AS max_starts_in_cluster,

    APPROX_QUANTILES(
        IF(
            start_count > 1,
            cluster_span_seconds,
            NULL
        ),
        100
    )[OFFSET(50)] AS median_repeated_cluster_span_seconds,

    APPROX_QUANTILES(
        IF(
            start_count > 1,
            cluster_span_seconds,
            NULL
        ),
        100
    )[OFFSET(90)] AS p90_repeated_cluster_span_seconds,

    MAX(
        IF(
            start_count > 1,
            cluster_span_seconds,
            NULL
        )
    ) AS max_repeated_cluster_span_seconds

FROM with_duration

GROUP BY game_mode

ORDER BY game_mode;


-- 15. Покрытие terminal-событий предыдущими start того же level / board

WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay_raw AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,

        CASE
            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN 'quickplay'
            ELSE 'progressive'
        END AS game_mode,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level,

        (
            SELECT ANY_VALUE(p.value.string_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'board'
        ) AS board

    FROM exact_deduplicated

    WHERE event_name IN (
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

-- Удаляем подтверждённые логические gameplay-дубли: одинаковые пользователь, timestamp и тип события.
gameplay AS (
    SELECT *
    FROM gameplay_raw

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            user_pseudo_id,
            event_timestamp,
            event_name
        ORDER BY event_bundle_sequence_id
    ) = 1
),

normalized AS (
    SELECT
        *,

        CASE
            WHEN game_mode = 'progressive'
                THEN CAST(level AS STRING)

            WHEN game_mode = 'quickplay'
                THEN board
        END AS game_key

    FROM gameplay
),

starts AS (
    SELECT
        user_pseudo_id,
        game_mode,
        game_key,
        event_timestamp AS start_timestamp

    FROM normalized

    WHERE event_name IN (
        'level_start',
        'level_start_quickplay'
    )
      AND game_key IS NOT NULL
),

terminal_events AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        game_mode,
        game_key

    FROM normalized

    WHERE event_name IN (
        'level_complete',
        'level_fail',
        'level_end',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay'
    )
),

matched AS (
    SELECT
        t.user_pseudo_id,
        t.event_timestamp,
        t.event_name,
        t.game_mode,
        t.game_key,

        -- Берём последний наблюдаемый start того же пользователя, режима и level / board.
        MAX(s.start_timestamp) AS matched_start_timestamp

    FROM terminal_events AS t

    LEFT JOIN starts AS s
        ON t.user_pseudo_id = s.user_pseudo_id
       AND t.game_mode = s.game_mode
       AND t.game_key = s.game_key
       AND s.start_timestamp < t.event_timestamp

    GROUP BY
        t.user_pseudo_id,
        t.event_timestamp,
        t.event_name,
        t.game_mode,
        t.game_key
),

prepared AS (
    SELECT
        *,

        SAFE_DIVIDE(
            event_timestamp - matched_start_timestamp,
            1000000
        ) AS seconds_from_start

    FROM matched
)

SELECT
    game_mode,
    event_name,

    COUNT(*) AS terminal_events,

    COUNTIF(game_key IS NULL)
        AS missing_game_key,

    COUNTIF(
        game_key IS NOT NULL
        AND matched_start_timestamp IS NOT NULL
    ) AS matched_to_previous_start,

    COUNTIF(
        game_key IS NOT NULL
        AND matched_start_timestamp IS NULL
    ) AS unmatched_with_known_key,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(
                game_key IS NOT NULL
                AND matched_start_timestamp IS NOT NULL
            ),
            COUNTIF(game_key IS NOT NULL)
        ),
        2
    ) AS match_share_pct,

    APPROX_QUANTILES(
        seconds_from_start,
        100
    )[OFFSET(50)] AS median_seconds_from_start,

    APPROX_QUANTILES(
        seconds_from_start,
        100
    )[OFFSET(90)] AS p90_seconds_from_start,

    APPROX_QUANTILES(
        seconds_from_start,
        100
    )[OFFSET(99)] AS p99_seconds_from_start,

    MAX(seconds_from_start)
        AS max_seconds_from_start

FROM prepared

GROUP BY
    game_mode,
    event_name

ORDER BY
    game_mode,
    event_name;

-- 16. Сопоставление start и terminal внутри наблюдаемой сессии

WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay_raw AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,

        CASE
            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN 'quickplay'
            ELSE 'progressive'
        END AS game_mode,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level,

        (
            SELECT ANY_VALUE(p.value.string_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'board'
        ) AS board

    FROM exact_deduplicated

    WHERE event_name IN (
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

-- Схлопываем подтверждённые логические gameplay-дубли.
gameplay AS (
    SELECT *
    FROM gameplay_raw

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            user_pseudo_id,
            event_timestamp,
            event_name
        ORDER BY event_bundle_sequence_id
    ) = 1
),

normalized_gameplay AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,
        game_mode,

        CASE
            WHEN game_mode = 'progressive'
                THEN CAST(level AS STRING)
            WHEN game_mode = 'quickplay'
                THEN board
        END AS game_key,

        1 AS event_priority,
        0 AS is_session_start

    FROM gameplay
),

-- Для определения границы сессии достаточно одного session_start на пользователя и timestamp. Это не является правилом дедупликации исходных данных.
session_boundaries AS (
    SELECT
        user_pseudo_id,
        event_timestamp,

        'session_start' AS event_name,
        CAST(NULL AS INT64) AS event_bundle_sequence_id,
        CAST(NULL AS STRING) AS game_mode,
        CAST(NULL AS STRING) AS game_key,

        0 AS event_priority,
        1 AS is_session_start

    FROM exact_deduplicated

    WHERE event_name = 'session_start'

    GROUP BY
        user_pseudo_id,
        event_timestamp
),

event_stream AS (
    SELECT *
    FROM normalized_gameplay

    UNION ALL

    SELECT *
    FROM session_boundaries
),

-- Нумеруем наблюдаемые сессии внутри пользователя. session_start получает приоритет перед gameplay-событием, если они имеют одинаковый timestamp.
with_session_number AS (
    SELECT
        *,

        SUM(is_session_start) OVER (
            PARTITION BY user_pseudo_id
            ORDER BY
                event_timestamp,
                event_priority,
                event_bundle_sequence_id,
                event_name
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS observed_session_number

    FROM event_stream
),

gameplay_with_session AS (
    SELECT
        *

    FROM with_session_number

    WHERE is_session_start = 0
),

with_matches AS (
    SELECT
        *,

        -- Последний более ранний start того же игрового ключа без ограничения наблюдаемой сессией.
        MAX(
            IF(
                event_name IN (
                    'level_start',
                    'level_start_quickplay'
                ),
                event_timestamp,
                NULL
            )
        ) OVER (
            PARTITION BY
                user_pseudo_id,
                game_mode,
                game_key
            ORDER BY event_timestamp
            RANGE BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS previous_start_any_session,

        -- Последний более ранний start того же игрового ключа внутри текущей наблюдаемой сессии.
        MAX(
            IF(
                event_name IN (
                    'level_start',
                    'level_start_quickplay'
                ),
                event_timestamp,
                NULL
            )
        ) OVER (
            PARTITION BY
                user_pseudo_id,
                observed_session_number,
                game_mode,
                game_key
            ORDER BY event_timestamp
            RANGE BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS previous_start_same_session

    FROM gameplay_with_session
),

terminal_events AS (
    SELECT
        *,

        SAFE_DIVIDE(
            event_timestamp - previous_start_any_session,
            1000000
        ) AS seconds_from_start_any_session,

        SAFE_DIVIDE(
            event_timestamp - previous_start_same_session,
            1000000
        ) AS seconds_from_start_same_session

    FROM with_matches

    WHERE event_name IN (
        'level_complete',
        'level_fail',
        'level_end',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay'
    )
)

SELECT
    game_mode,
    event_name,

    COUNT(*) AS terminal_events,

    COUNTIF(game_key IS NULL)
        AS missing_game_key,

    -- События, расположенные до первого наблюдаемого session_start пользователя.
    COUNTIF(
        game_key IS NOT NULL
        AND observed_session_number = 0
    ) AS before_first_observed_session,

    COUNTIF(
        game_key IS NOT NULL
        AND previous_start_any_session IS NOT NULL
    ) AS matched_without_session_limit,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(
                game_key IS NOT NULL
                AND previous_start_any_session IS NOT NULL
            ),
            COUNTIF(game_key IS NOT NULL)
        ),
        2
    ) AS match_share_without_session_pct,

    -- Ниже оцениваем только события после хотя бы одного наблюдаемого session_start.
    COUNTIF(
        game_key IS NOT NULL
        AND observed_session_number > 0
    ) AS terminals_with_observed_session,

    COUNTIF(
        game_key IS NOT NULL
        AND observed_session_number > 0
        AND previous_start_same_session IS NOT NULL
    ) AS matched_same_session,

    COUNTIF(
        game_key IS NOT NULL
        AND observed_session_number > 0
        AND previous_start_same_session IS NULL
    ) AS unmatched_same_session,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(
                game_key IS NOT NULL
                AND observed_session_number > 0
                AND previous_start_same_session IS NOT NULL
            ),
            COUNTIF(
                game_key IS NOT NULL
                AND observed_session_number > 0
            )
        ),
        2
    ) AS match_share_same_session_pct,

    APPROX_QUANTILES(
        IF(
            observed_session_number > 0,
            seconds_from_start_same_session,
            NULL
        ),
        100
    )[OFFSET(50)] AS median_seconds_same_session,

    APPROX_QUANTILES(
        IF(
            observed_session_number > 0,
            seconds_from_start_same_session,
            NULL
        ),
        100
    )[OFFSET(90)] AS p90_seconds_same_session,

    APPROX_QUANTILES(
        IF(
            observed_session_number > 0,
            seconds_from_start_same_session,
            NULL
        ),
        100
    )[OFFSET(99)] AS p99_seconds_same_session,

    MAX(
        IF(
            observed_session_number > 0,
            seconds_from_start_same_session,
            NULL
        )
    ) AS max_seconds_same_session

FROM terminal_events

GROUP BY
    game_mode,
    event_name

ORDER BY
    game_mode,
    event_name;


-- 17. Временная устойчивость сопоставления start -> terminal внутри наблюдаемой сессии

WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
),

gameplay_raw AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,

        CASE
            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN 'quickplay'
            ELSE 'progressive'
        END AS game_mode,

        COALESCE(
            (
                SELECT ANY_VALUE(p.value.int_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'level'
            ),
            CAST(
                (
                    SELECT ANY_VALUE(p.value.double_value)
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'level'
                ) AS INT64
            )
        ) AS level,

        (
            SELECT ANY_VALUE(p.value.string_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'board'
        ) AS board

    FROM exact_deduplicated

    WHERE event_name IN (
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

-- Удаляем подтверждённые логические gameplay-дубли.
gameplay AS (
    SELECT *
    FROM gameplay_raw

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            user_pseudo_id,
            event_timestamp,
            event_name
        ORDER BY event_bundle_sequence_id
    ) = 1
),

normalized_gameplay AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,
        event_bundle_sequence_id,
        game_mode,

        CASE
            WHEN game_mode = 'progressive'
                THEN CAST(level AS STRING)
            WHEN game_mode = 'quickplay'
                THEN board
        END AS game_key,

        1 AS event_priority,
        0 AS is_session_start

    FROM gameplay
),

session_boundaries AS (
    SELECT
        user_pseudo_id,
        event_timestamp,

        'session_start' AS event_name,
        CAST(NULL AS INT64) AS event_bundle_sequence_id,
        CAST(NULL AS STRING) AS game_mode,
        CAST(NULL AS STRING) AS game_key,

        0 AS event_priority,
        1 AS is_session_start

    FROM exact_deduplicated

    WHERE event_name = 'session_start'

    GROUP BY
        user_pseudo_id,
        event_timestamp
),

event_stream AS (
    SELECT * FROM normalized_gameplay

    UNION ALL

    SELECT * FROM session_boundaries
),

with_session_number AS (
    SELECT
        *,

        SUM(is_session_start) OVER (
            PARTITION BY user_pseudo_id
            ORDER BY
                event_timestamp,
                event_priority,
                event_bundle_sequence_id,
                event_name
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS observed_session_number

    FROM event_stream
),

gameplay_with_session AS (
    SELECT *
    FROM with_session_number
    WHERE is_session_start = 0
),

with_previous_start AS (
    SELECT
        *,

        MAX(
            IF(
                event_name IN (
                    'level_start',
                    'level_start_quickplay'
                ),
                event_timestamp,
                NULL
            )
        ) OVER (
            PARTITION BY
                user_pseudo_id,
                observed_session_number,
                game_mode,
                game_key
            ORDER BY event_timestamp
            RANGE BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS previous_start_same_session

    FROM gameplay_with_session
),

matched_terminal AS (
    SELECT
        game_mode,
        event_name,

        SAFE_DIVIDE(
            event_timestamp - previous_start_same_session,
            1000000
        ) AS seconds_from_start

    FROM with_previous_start

    WHERE event_name IN (
        'level_complete',
        'level_fail',
        'level_end',
        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay'
    )
      AND game_key IS NOT NULL
      AND observed_session_number > 0
      AND previous_start_same_session IS NOT NULL
)

SELECT
    game_mode,
    event_name,

    COUNT(*) AS matched_terminal_events,

    COUNTIF(seconds_from_start <= 300)
        AS within_5_min,

    COUNTIF(seconds_from_start <= 600)
        AS within_10_min,

    COUNTIF(seconds_from_start <= 1800)
        AS within_30_min,

    COUNTIF(seconds_from_start <= 3600)
        AS within_1_hour,

    COUNTIF(seconds_from_start <= 21600)
        AS within_6_hours,

    COUNTIF(seconds_from_start <= 86400)
        AS within_24_hours,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(seconds_from_start <= 300),
            COUNT(*)
        ),
        2
    ) AS share_within_5_min_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(seconds_from_start <= 600),
            COUNT(*)
        ),
        2
    ) AS share_within_10_min_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(seconds_from_start <= 1800),
            COUNT(*)
        ),
        2
    ) AS share_within_30_min_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(seconds_from_start <= 3600),
            COUNT(*)
        ),
        2
    ) AS share_within_1_hour_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(seconds_from_start <= 21600),
            COUNT(*)
        ),
        2
    ) AS share_within_6_hours_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(seconds_from_start <= 86400),
            COUNT(*)
        ),
        2
    ) AS share_within_24_hours_pct,

    APPROX_QUANTILES(
        seconds_from_start,
        1000
    )[OFFSET(950)] AS p95_seconds,

    APPROX_QUANTILES(
        seconds_from_start,
        1000
    )[OFFSET(990)] AS p99_seconds,

    APPROX_QUANTILES(
        seconds_from_start,
        1000
    )[OFFSET(995)] AS p995_seconds,

    APPROX_QUANTILES(
        seconds_from_start,
        1000
    )[OFFSET(999)] AS p999_seconds

FROM matched_terminal

GROUP BY
    game_mode,
    event_name

ORDER BY
    game_mode,
    event_name;


-- 19. Связь retry/reset с предыдущим и следующим start

WITH exact_dedup AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name IN (
        'session_start',

        'level_start',
        'level_retry',
        'level_reset',

        'level_start_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(
            STRUCT(
                event_date,
                event_timestamp,
                event_name,
                event_params,
                event_previous_timestamp,
                event_value_in_usd,
                event_bundle_sequence_id,
                event_server_timestamp_offset,
                user_id,
                user_pseudo_id,
                privacy_info,
                user_properties,
                user_first_touch_timestamp,
                user_ltv,
                device,
                geo,
                app_info,
                traffic_source,
                stream_id,
                platform,
                event_dimensions
            )
        )
    ) = 1
),

normalized AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,

        CASE
            WHEN event_name = 'session_start'
                THEN NULL
            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN 'quickplay'
            ELSE 'progressive'
        END AS game_mode,

        CASE
            WHEN event_name = 'session_start'
                THEN 'session_start'
            WHEN event_name IN (
                'level_start',
                'level_start_quickplay'
            )
                THEN 'start'
            WHEN event_name IN (
                'level_retry',
                'level_retry_quickplay'
            )
                THEN 'retry'
            WHEN event_name IN (
                'level_reset',
                'level_reset_quickplay'
            )
                THEN 'reset'
        END AS event_type,

        CASE
            WHEN event_name = 'session_start'
                THEN NULL

            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN (
                    SELECT p.value.string_value
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'board'
                )

            ELSE CAST(
                COALESCE(
                    (
                        SELECT p.value.int_value
                        FROM UNNEST(event_params) AS p
                        WHERE p.key = 'level'
                    ),
                    CAST(
                        (
                            SELECT p.value.double_value
                            FROM UNNEST(event_params) AS p
                            WHERE p.key = 'level'
                        ) AS INT64
                    )
                ) AS STRING
            )
        END AS game_key

    FROM exact_dedup
),

logical_dedup AS (
    SELECT DISTINCT
        user_pseudo_id,
        event_timestamp,
        event_name,
        game_mode,
        event_type,
        game_key
    FROM normalized
),

gameplay_stream AS (
    SELECT
        *,

        COALESCE(
            MAX(
                IF(
                    event_type = 'session_start',
                    event_timestamp,
                    NULL
                )
            ) OVER (
                PARTITION BY user_pseudo_id
                ORDER BY event_timestamp
                RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ),
            -1
        ) AS observed_session_start

    FROM logical_dedup
),

anchors AS (
    SELECT
        user_pseudo_id,
        event_timestamp AS anchor_timestamp,
        game_mode,
        event_type AS anchor_type,
        game_key,
        observed_session_start
    FROM gameplay_stream
    WHERE event_type IN ('retry', 'reset')
      AND game_key IS NOT NULL
),

previous_start AS (
    SELECT
        a.user_pseudo_id,
        a.anchor_timestamp,
        a.game_mode,
        a.anchor_type,
        a.game_key,
        a.observed_session_start,

        MAX(s.event_timestamp) AS previous_start_timestamp

    FROM anchors AS a

    LEFT JOIN gameplay_stream AS s
        ON s.user_pseudo_id = a.user_pseudo_id
       AND s.game_mode = a.game_mode
       AND s.game_key = a.game_key
       AND s.observed_session_start = a.observed_session_start
       AND s.event_type = 'start'
       AND s.event_timestamp < a.anchor_timestamp
       AND a.anchor_timestamp - s.event_timestamp
            <= 30 * 60 * 1000000

    GROUP BY
        a.user_pseudo_id,
        a.anchor_timestamp,
        a.game_mode,
        a.anchor_type,
        a.game_key,
        a.observed_session_start
),

next_start AS (
    SELECT
        a.user_pseudo_id,
        a.anchor_timestamp,
        a.game_mode,
        a.anchor_type,
        a.game_key,
        a.observed_session_start,

        MIN(s.event_timestamp) AS next_start_timestamp

    FROM anchors AS a

    LEFT JOIN gameplay_stream AS s
        ON s.user_pseudo_id = a.user_pseudo_id
       AND s.game_mode = a.game_mode
       AND s.game_key = a.game_key
       AND s.observed_session_start = a.observed_session_start
       AND s.event_type = 'start'
       AND s.event_timestamp > a.anchor_timestamp
       AND s.event_timestamp - a.anchor_timestamp
            <= 30 * 60 * 1000000

    GROUP BY
        a.user_pseudo_id,
        a.anchor_timestamp,
        a.game_mode,
        a.anchor_type,
        a.game_key,
        a.observed_session_start
),

combined AS (
    SELECT
        p.*,
        n.next_start_timestamp
    FROM previous_start AS p
    JOIN next_start AS n
        USING (
            user_pseudo_id,
            anchor_timestamp,
            game_mode,
            anchor_type,
            game_key,
            observed_session_start
        )
)

SELECT
    game_mode,
    anchor_type,
    COUNT(*) AS anchor_events,

    COUNTIF(
        previous_start_timestamp IS NOT NULL
    ) AS with_previous_start_30m,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(previous_start_timestamp IS NOT NULL),
            COUNT(*)
        ),
        2
    ) AS previous_start_30m_pct,

    COUNTIF(
        next_start_timestamp IS NOT NULL
    ) AS with_next_start_30m,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(next_start_timestamp IS NOT NULL),
            COUNT(*)
        ),
        2
    ) AS next_start_30m_pct,

    COUNTIF(
        next_start_timestamp - anchor_timestamp
            <= 1 * 1000000
    ) AS next_start_within_1s,

    COUNTIF(
        next_start_timestamp - anchor_timestamp
            <= 5 * 1000000
    ) AS next_start_within_5s,

    COUNTIF(
        next_start_timestamp - anchor_timestamp
            <= 30 * 1000000
    ) AS next_start_within_30s,

    COUNTIF(
        next_start_timestamp - anchor_timestamp
            <= 2 * 60 * 1000000
    ) AS next_start_within_2m,

    COUNTIF(
        previous_start_timestamp IS NOT NULL
        AND next_start_timestamp IS NOT NULL
    ) AS between_two_starts

FROM combined

GROUP BY
    game_mode,
    anchor_type

ORDER BY
    game_mode,
    anchor_type;


-- 19.1 Связь retry/reset с complete/fail/end

WITH exact_dedup AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name IN (
        'session_start',

        'level_complete',
        'level_fail',
        'level_end',
        'level_retry',
        'level_reset',

        'level_complete_quickplay',
        'level_fail_quickplay',
        'level_end_quickplay',
        'level_retry_quickplay',
        'level_reset_quickplay'
    )
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(
            STRUCT(
                event_date,
                event_timestamp,
                event_name,
                event_params,
                event_previous_timestamp,
                event_value_in_usd,
                event_bundle_sequence_id,
                event_server_timestamp_offset,
                user_id,
                user_pseudo_id,
                privacy_info,
                user_properties,
                user_first_touch_timestamp,
                user_ltv,
                device,
                geo,
                app_info,
                traffic_source,
                stream_id,
                platform,
                event_dimensions
            )
        )
    ) = 1
),

normalized AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,

        CASE
            WHEN event_name = 'session_start'
                THEN NULL
            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN 'quickplay'
            ELSE 'progressive'
        END AS game_mode,

        CASE
            WHEN event_name = 'session_start'
                THEN 'session_start'
            WHEN event_name IN (
                'level_complete',
                'level_complete_quickplay'
            )
                THEN 'complete'
            WHEN event_name IN (
                'level_fail',
                'level_fail_quickplay'
            )
                THEN 'fail'
            WHEN event_name IN (
                'level_end',
                'level_end_quickplay'
            )
                THEN 'end'
            WHEN event_name IN (
                'level_retry',
                'level_retry_quickplay'
            )
                THEN 'retry'
            WHEN event_name IN (
                'level_reset',
                'level_reset_quickplay'
            )
                THEN 'reset'
        END AS event_type,

        CASE
            WHEN event_name = 'session_start'
                THEN NULL

            WHEN ENDS_WITH(event_name, '_quickplay')
                THEN (
                    SELECT p.value.string_value
                    FROM UNNEST(event_params) AS p
                    WHERE p.key = 'board'
                )

            ELSE CAST(
                COALESCE(
                    (
                        SELECT p.value.int_value
                        FROM UNNEST(event_params) AS p
                        WHERE p.key = 'level'
                    ),
                    CAST(
                        (
                            SELECT p.value.double_value
                            FROM UNNEST(event_params) AS p
                            WHERE p.key = 'level'
                        ) AS INT64
                    )
                ) AS STRING
            )
        END AS game_key

    FROM exact_dedup
),

logical_dedup AS (
    SELECT DISTINCT
        user_pseudo_id,
        event_timestamp,
        event_name,
        game_mode,
        event_type,
        game_key
    FROM normalized
),

gameplay_stream AS (
    SELECT
        *,

        COALESCE(
            MAX(
                IF(
                    event_type = 'session_start',
                    event_timestamp,
                    NULL
                )
            ) OVER (
                PARTITION BY user_pseudo_id
                ORDER BY event_timestamp
                RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ),
            -1
        ) AS observed_session_start

    FROM logical_dedup
),

anchors AS (
    SELECT
        user_pseudo_id,
        event_timestamp AS anchor_timestamp,
        game_mode,
        event_type AS anchor_type,
        game_key,
        observed_session_start
    FROM gameplay_stream
    WHERE event_type IN ('retry', 'reset')
      AND game_key IS NOT NULL
),

anchor_counts AS (
    SELECT
        game_mode,
        anchor_type,
        COUNT(*) AS anchor_events
    FROM anchors
    GROUP BY
        game_mode,
        anchor_type
),

nearest_related AS (
    SELECT
        a.user_pseudo_id,
        a.anchor_timestamp,
        a.game_mode,
        a.anchor_type,
        a.game_key,

        r.event_type AS related_type,

        r.event_timestamp - a.anchor_timestamp
            AS time_diff_micros

    FROM anchors AS a

    JOIN gameplay_stream AS r
        ON r.user_pseudo_id = a.user_pseudo_id
       AND r.game_mode = a.game_mode
       AND r.game_key = a.game_key
       AND r.observed_session_start = a.observed_session_start
       AND r.event_type IN ('complete', 'fail', 'end')
       AND ABS(
            r.event_timestamp - a.anchor_timestamp
       ) <= 30 * 60 * 1000000

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            a.user_pseudo_id,
            a.anchor_timestamp,
            a.game_mode,
            a.anchor_type,
            a.game_key,
            r.event_type
        ORDER BY
            ABS(r.event_timestamp - a.anchor_timestamp),
            r.event_timestamp
    ) = 1
),

match_summary AS (
    SELECT
        game_mode,
        anchor_type,
        related_type,

        COUNT(*) AS anchors_with_related_30m,

        COUNTIF(
            ABS(time_diff_micros) <= 1 * 1000000
        ) AS within_1s,

        COUNTIF(
            ABS(time_diff_micros) <= 5 * 1000000
        ) AS within_5s,

        COUNTIF(
            ABS(time_diff_micros) <= 30 * 1000000
        ) AS within_30s,

        COUNTIF(
            ABS(time_diff_micros) <= 2 * 60 * 1000000
        ) AS within_2m,

        COUNTIF(
            time_diff_micros < 0
        ) AS related_before,

        COUNTIF(
            time_diff_micros = 0
        ) AS same_timestamp,

        COUNTIF(
            time_diff_micros > 0
        ) AS related_after

    FROM nearest_related

    GROUP BY
        game_mode,
        anchor_type,
        related_type
),

related_types AS (
    SELECT 'complete' AS related_type
    UNION ALL
    SELECT 'fail'
    UNION ALL
    SELECT 'end'
),

result_grid AS (
    SELECT
        a.game_mode,
        a.anchor_type,
        a.anchor_events,
        r.related_type
    FROM anchor_counts AS a
    CROSS JOIN related_types AS r
)

SELECT
    g.game_mode,
    g.anchor_type,
    g.related_type,
    g.anchor_events,

    COALESCE(
        s.anchors_with_related_30m,
        0
    ) AS anchors_with_related_30m,

    ROUND(
        100 * SAFE_DIVIDE(
            COALESCE(s.anchors_with_related_30m, 0),
            g.anchor_events
        ),
        2
    ) AS related_30m_pct,

    COALESCE(s.within_1s, 0)
        AS within_1s,

    COALESCE(s.within_5s, 0)
        AS within_5s,

    COALESCE(s.within_30s, 0)
        AS within_30s,

    COALESCE(s.within_2m, 0)
        AS within_2m,

    COALESCE(s.related_before, 0)
        AS related_before,

    COALESCE(s.same_timestamp, 0)
        AS same_timestamp,

    COALESCE(s.related_after, 0)
        AS related_after

FROM result_grid AS g

LEFT JOIN match_summary AS s
    USING (
        game_mode,
        anchor_type,
        related_type
    )

ORDER BY
    game_mode,
    anchor_type,
    related_type;