CREATE SCHEMA IF NOT EXISTS `sixth-tempo-506411-d9.floodit_analytics`;

CREATE OR REPLACE TABLE `sixth-tempo-506411-d9.floodit_analytics.stg_events`
CLUSTER BY user_pseudo_id, event_name
AS

WITH raw_events AS (
    SELECT AS STRUCT t.*
    FROM `firebase-public-project.analytics_153293282.events_*` AS t
),

deduplicated AS (
    SELECT *
    FROM raw_events
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TO_JSON_STRING(raw_events)
    ) = 1
)

SELECT
    TO_HEX(SHA256(TO_JSON_STRING(deduplicated))) AS stg_event_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
    event_name,
    user_pseudo_id,
    TIMESTAMP_MICROS(user_first_touch_timestamp) AS user_first_touch_timestamp,
    platform,
    COALESCE(app_info.install_source, app_info.install_store) AS install_source,
    event_value_in_usd,
    event_params,
    user_properties
FROM deduplicated;