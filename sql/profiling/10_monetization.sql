-- Подготовка monetization-событий после exact deduplication

CREATE TEMP TABLE monetization_events AS

WITH exact_deduplicated AS (
    SELECT *
    FROM `firebase-public-project.analytics_153293282.events_*` AS e

    WHERE event_name IN (
        'in_app_purchase',
        'ad_reward',
        'spend_virtual_currency',
        'use_extra_steps',
        'no_more_extra_steps'
    )

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(e)
    ) = 1
)

SELECT
    user_pseudo_id,
    event_timestamp,
    event_date,
    event_name,
    platform,
    event_value_in_usd,

    (
        SELECT ANY_VALUE(p.value.string_value)
        FROM UNNEST(event_params) AS p
        WHERE p.key = 'product_id'
    ) AS product_id,

    (
        SELECT ANY_VALUE(p.value.string_value)
        FROM UNNEST(event_params) AS p
        WHERE p.key = 'product_name'
    ) AS product_name,

    (
        SELECT ANY_VALUE(p.value.string_value)
        FROM UNNEST(event_params) AS p
        WHERE p.key = 'currency'
    ) AS currency,

    (
        SELECT ANY_VALUE(p.value.int_value)
        FROM UNNEST(event_params) AS p
        WHERE p.key = 'price'
    ) AS price,

    (
        SELECT ANY_VALUE(p.value.int_value)
        FROM UNNEST(event_params) AS p
        WHERE p.key = 'quantity'
    ) AS quantity,

    COALESCE(
        (
            SELECT CAST(ANY_VALUE(p.value.int_value) AS FLOAT64)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'value'
        ),
        (
            SELECT ANY_VALUE(p.value.double_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'value'
        )
    ) AS value,

    (
        SELECT ANY_VALUE(p.value.int_value)
        FROM UNNEST(event_params) AS p
        WHERE p.key = 'validated'
    ) AS validated,

    (
        SELECT ANY_VALUE(p.value.string_value)
        FROM UNNEST(event_params) AS p
        WHERE p.key = 'virtual_currency_name'
    ) AS virtual_currency_name,

    (
        SELECT ANY_VALUE(p.value.string_value)
        FROM UNNEST(event_params) AS p
        WHERE p.key = 'item_name'
    ) AS item_name,

    (
        SELECT ANY_VALUE(p.value.string_value)
        FROM UNNEST(event_params) AS p
        WHERE p.key = 'type'
    ) AS reward_type,

    (
        SELECT ANY_VALUE(p.value.string_value)
        FROM UNNEST(event_params) AS p
        WHERE p.key = 'ad_unit_code'
    ) AS ad_unit_code,

    COALESCE(
        (
            SELECT ANY_VALUE(p.value.int_value)
            FROM UNNEST(event_params) AS p
            WHERE p.key = 'ad_event_id'
        ),
        CAST(
            (
                SELECT ANY_VALUE(p.value.double_value)
                FROM UNNEST(event_params) AS p
                WHERE p.key = 'ad_event_id'
            ) AS INT64
        )
    ) AS ad_event_id,

    (
        SELECT STRING_AGG(
            TO_JSON_STRING(p),
            '|' ORDER BY p.key
        )
        FROM UNNEST(event_params) AS p
    ) AS event_params_canonical

FROM exact_deduplicated;


-- 1. Профиль in_app_purchase

SELECT
    platform,
    product_id,
    product_name,
    currency,
    quantity,
    price,
    value,
    validated,

    COUNT(*) AS purchase_events,
    COUNT(DISTINCT user_pseudo_id) AS purchasers,

    MIN(event_value_in_usd)
        AS min_event_value_in_usd,

    MAX(event_value_in_usd)
        AS max_event_value_in_usd

FROM monetization_events

WHERE event_name = 'in_app_purchase'

GROUP BY
    platform,
    product_id,
    product_name,
    currency,
    quantity,
    price,
    value,
    validated

ORDER BY
    purchase_events DESC,
    platform,
    product_id;

-- 2. Согласованность параметров in_app_purchase

SELECT
    COUNT(*) AS purchase_events,
    COUNT(DISTINCT user_pseudo_id) AS purchasers,

    COUNT(DISTINCT product_id)
        AS distinct_products,

    COUNT(DISTINCT currency)
        AS distinct_currencies,

    COUNTIF(
        product_id IS NULL OR product_id = ''
    ) AS missing_product_id,

    COUNTIF(
        product_name IS NULL OR product_name = ''
    ) AS missing_product_name,

    COUNTIF(price IS NULL)
        AS missing_price,

    COUNTIF(price <= 0)
        AS non_positive_price,

    COUNTIF(currency IS NULL OR currency = '')
        AS missing_currency,

    COUNTIF(quantity IS NULL)
        AS missing_quantity,

    COUNTIF(quantity != 1)
        AS quantity_not_one,

    COUNTIF(validated IS NULL)
        AS missing_validated,

    COUNTIF(validated != 1)
        AS not_validated,

    COUNTIF(event_value_in_usd IS NULL)
        AS missing_event_value_in_usd,

    COUNTIF(event_value_in_usd <= 0)
        AS non_positive_event_value_in_usd,

    COUNTIF(value IS NULL)
        AS missing_value,

    MIN(value) AS min_value,
    MAX(value) AS max_value,

    -- Проверка возможного соответствия price и USD-value
    -- выполняется только для USD, без предположений о FX.
    COUNTIF(
        currency = 'USD'
        AND event_value_in_usd IS NOT NULL
        AND ABS(
            price / 1000000.0 - event_value_in_usd
        ) > 0.000001
    ) AS usd_price_value_mismatches

FROM monetization_events

WHERE event_name = 'in_app_purchase';

-- 3. Однозначность product_id -> product_name / price / currency

SELECT
    product_id,

    ARRAY_AGG(
        DISTINCT product_name
        IGNORE NULLS
        ORDER BY product_name
    ) AS product_names,

    ARRAY_AGG(
        DISTINCT currency
        IGNORE NULLS
        ORDER BY currency
    ) AS currencies,

    COUNT(DISTINCT price)
        AS distinct_prices,

    MIN(price) AS min_price,
    MAX(price) AS max_price,

    COUNT(*) AS purchase_events,
    COUNT(DISTINCT user_pseudo_id) AS purchasers

FROM monetization_events

WHERE event_name = 'in_app_purchase'

GROUP BY product_id

ORDER BY product_id;


-- 4. Для каких событий заполнен top-level event_value_in_usd

SELECT
    event_name,
    COUNT(*) AS events_with_value_in_usd,
    COUNT(DISTINCT user_pseudo_id) AS users,

    MIN(event_value_in_usd) AS min_value_in_usd,
    MAX(event_value_in_usd) AS max_value_in_usd

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_value_in_usd IS NOT NULL

GROUP BY event_name

ORDER BY events_with_value_in_usd DESC;


-- 5. Профиль rewarded ads и extra-steps событий

SELECT
    event_name,

    COUNT(*) AS event_count,
    COUNT(DISTINCT user_pseudo_id) AS user_count,

    COUNTIF(value IS NULL)
        AS missing_value,

    MIN(value) AS min_value,
    MAX(value) AS max_value,

    COUNTIF(virtual_currency_name IS NULL)
        AS missing_virtual_currency_name,

    ARRAY_AGG(
        DISTINCT virtual_currency_name
        IGNORE NULLS
        ORDER BY virtual_currency_name
    ) AS virtual_currency_names,

    COUNTIF(item_name IS NULL)
        AS missing_item_name,

    ARRAY_AGG(
        DISTINCT item_name
        IGNORE NULLS
        ORDER BY item_name
    ) AS item_names,

    COUNTIF(reward_type IS NULL)
        AS missing_reward_type,

    ARRAY_AGG(
        DISTINCT reward_type
        IGNORE NULLS
        ORDER BY reward_type
    ) AS reward_types,

    COUNTIF(ad_unit_code IS NULL)
        AS missing_ad_unit_code,

    COUNTIF(ad_event_id IS NULL)
        AS missing_ad_event_id,

    COUNT(DISTINCT ad_event_id)
        AS distinct_ad_event_ids

FROM monetization_events

WHERE event_name IN (
    'ad_reward',
    'spend_virtual_currency',
    'use_extra_steps',
    'no_more_extra_steps'
)

GROUP BY event_name

ORDER BY event_name;

-- 6. Коллизии monetization-событий после exact deduplication

WITH collisions AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        event_name,

        COUNT(*) AS event_count,

        COUNT(DISTINCT event_params_canonical)
            AS parameter_variants

    FROM monetization_events

    GROUP BY
        user_pseudo_id,
        event_timestamp,
        event_name

    HAVING COUNT(*) > 1
)

SELECT
    event_name,

    COUNT(*) AS collision_groups,
    SUM(event_count) AS events_in_collision_groups,

    COUNTIF(parameter_variants > 1)
        AS groups_with_different_params,

    MAX(event_count)
        AS max_events_same_timestamp

FROM collisions

GROUP BY event_name

ORDER BY collision_groups DESC;


-- 7. Связь spend_virtual_currency и use_extra_steps

WITH spend AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        value,
        item_name
    FROM monetization_events
    WHERE event_name = 'spend_virtual_currency'
),

use_steps AS (
    SELECT
        user_pseudo_id,
        event_timestamp,
        value,
        item_name
    FROM monetization_events
    WHERE event_name = 'use_extra_steps'
),

spend_checked AS (
    SELECT
        s.user_pseudo_id,
        s.event_timestamp,
        s.value,
        s.item_name,

        MIN(
            ABS(u.event_timestamp - s.event_timestamp)
        ) / 1000000.0 AS nearest_any_seconds,

        MIN(
            IF(
                u.value = s.value
                AND u.item_name = s.item_name,
                ABS(u.event_timestamp - s.event_timestamp),
                NULL
            )
        ) / 1000000.0 AS nearest_same_payload_seconds

    FROM spend AS s

    LEFT JOIN use_steps AS u
        ON s.user_pseudo_id = u.user_pseudo_id
       AND ABS(u.event_timestamp - s.event_timestamp)
           <= 30 * 1000000

    GROUP BY
        s.user_pseudo_id,
        s.event_timestamp,
        s.value,
        s.item_name
),

use_checked AS (
    SELECT
        u.user_pseudo_id,
        u.event_timestamp,
        u.value,
        u.item_name,

        MIN(
            ABS(s.event_timestamp - u.event_timestamp)
        ) / 1000000.0 AS nearest_any_seconds,

        MIN(
            IF(
                s.value = u.value
                AND s.item_name = u.item_name,
                ABS(s.event_timestamp - u.event_timestamp),
                NULL
            )
        ) / 1000000.0 AS nearest_same_payload_seconds

    FROM use_steps AS u

    LEFT JOIN spend AS s
        ON u.user_pseudo_id = s.user_pseudo_id
       AND ABS(s.event_timestamp - u.event_timestamp)
           <= 30 * 1000000

    GROUP BY
        u.user_pseudo_id,
        u.event_timestamp,
        u.value,
        u.item_name
)

SELECT
    'spend_virtual_currency' AS anchor_event,

    COUNT(*) AS anchor_events,

    COUNTIF(nearest_any_seconds = 0)
        AS exact_timestamp_any_payload,

    COUNTIF(nearest_same_payload_seconds = 0)
        AS exact_timestamp_same_payload,

    COUNTIF(nearest_same_payload_seconds <= 1)
        AS same_payload_within_1_sec,

    COUNTIF(nearest_same_payload_seconds <= 5)
        AS same_payload_within_5_sec,

    COUNTIF(nearest_same_payload_seconds <= 30)
        AS same_payload_within_30_sec,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(nearest_same_payload_seconds = 0),
            COUNT(*)
        ),
        2
    ) AS exact_same_payload_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(nearest_same_payload_seconds <= 30),
            COUNT(*)
        ),
        2
    ) AS within_30_sec_same_payload_pct

FROM spend_checked

UNION ALL

SELECT
    'use_extra_steps' AS anchor_event,

    COUNT(*) AS anchor_events,

    COUNTIF(nearest_any_seconds = 0),
    COUNTIF(nearest_same_payload_seconds = 0),
    COUNTIF(nearest_same_payload_seconds <= 1),
    COUNTIF(nearest_same_payload_seconds <= 5),
    COUNTIF(nearest_same_payload_seconds <= 30),

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(nearest_same_payload_seconds = 0),
            COUNT(*)
        ),
        2
    ),

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(nearest_same_payload_seconds <= 30),
            COUNT(*)
        ),
        2
    )

FROM use_checked;