# Reference values #

## app_info ##

app_info.id:

    com.google.flood2, com.labpixies.flood

app_info.firebase_app_id:

    1:300830567303:android:9b9ba2ce17104d0c, 1:300830567303:ios:09b1ab1d3ca29bda

app_info.version:

    2.6.6, 2.6.29, 2.4.1, 2.4, 2.5.5, 2.48, 2.62, 2.53, 2.41, 2.6.7, 2.6.22, 2.60, 2.6.26, 2.6.8, 2.6.21, 2.0, 2.51, 2.6.20, 2.6.30, 2.52, 2.6.10, 2.6.31, 2.2.5, 2.50, 2.46, 2.6.25, 2.63, 2.6.9, 2.6.27, 2.59, 2.57, 2.58, 2.3.7, 2.6.24

app_info.install_store:

    iTunes, com.android.vending, NULL

app_info.install_source:

    iTunes, com.android.vending, NULL;

## device ##

device.category:

    mobile, tablet

device.operating_system:

    IOS, ANDROID, NULL

device.vendor_id:

    NULL

device.advertising_id:

    NULL

device.language:

    en-ca, en-hk, pt-pt, sv-se, de, en-ae, es-cl, hr-hr, en-mn, bs-ba, gsw-us, ja-gb, en-bs, ru-az, ar-us, en-ec, en-xa, en-es, en-ma, ko-kr, es-ar, sl-si, fr-ch, tr-tr, en-my, es-pe, en-br, en-uk, de-us, es-gt, en-kr, zh-hant-mo, en-kw, nb-ic, en-ch, en-ai, es-pr, fr-cv, en-hr, en-mu, ar-qa, es-mx, en-za, es-us, it-it, es-hn, ar-sa, en-pe, ca-es, zh-hant-tw, en-mx, cs-cz, en-pr, sr-rs, en-tz, en-001, ja-al, en-ar, fr-sn, fr-dz, en-eg, ar-jo, ja-mw, pt, gu-in, es-419, en-jp, en-ie, he-il, en-tr, en-rs, es, en-it, nl-us, en-vu, en-ro, en-pk, sr-bg, fr-lu, zh-sg, fr-ca, zh-tw, fr, de-ch, ar-kw, en-lt, es-sv, nb, en-co, pl-us, es-cr, bn-bd, en-mt, ja-jp, pt-br, en-gu, en-tw, en-jo, en-fr, zh-hant, ru, ja, ja-de, id-sa, nl-be, en-de, en-vi, es-ec, mn-mn, en-lb, en-cl, lo-la, en-qa, fr-mx, et-ee, nl-nl, en-gb, en-in, de-de, hi-in, vi-vn, ru-ru, es-co, ar-eg, en-se, pl-pl, zh-hans-us, tr-cn, ar-dz, vi-us, en-na, zh-hant-us, ja-dk, fr-au, is-is, ca-ad, fr-ci, en-us, es-es, hu-hu, en-id, nb-no, zh-hans-cn, en-cn, en-il, ar-ae, en-si, en-as, fr-us, en-pt, th-th, en-th, sk-sk, ro-ro, en-sa, pt-us, bg-bg, pt-jp, es-ve, zh-hans-hk, zh-hans, es-pa, nl, ms-my, fr-fr, de-at, zh-cn, te-in, uk-ua, ar-il, fr-mq, ja-us, fr-lb, ja-kr, en-ru, mr-in, en-bh, zh-hant-ca, en-cz, en-ng, en-kh, sv-us, ar-bh, en-cy, en-jm, lt-lt, pl-gb, da-dk, en-nz, in-id, en-sg, ru-us, en-ph, ru-ua, fr-pf, en-vn, zh-hant-hk, ko, en-nc, bn-in, zh-hans-my, da-us, en-do, fr-td, en-au, iw-il, en, zh-hk, fr-be, en-nl, ar-iq, ru-kz, zh-hans-it, haw-us, el-gr, en-pg, ja-np, fr-jp, en-ax, es-uy, fr-cd, en-be, en-gr, zh-hans-au, en-gt, en-ag, ta-in, en-tt, fr-kh

device.is_limited_ad_tracking:

    Yes, No

device.time_zone_offset_seconds :

    -21600, -7200, 39600, -3600, -16200, -28800, 36000, 0, 12600, 32400, 28800, -18000, -25200, 10800, 18000, 25200, 43200, 3600, -36000, 34200, 21600, 46800, 14400, 20700, 16200, 23400, 19800, -10800, -14400, 7200, -9000

device.browser:

    NULL

device.browser-version:

    NULL

device.web_info.browser:

    NULL;

device.web_info.browser_version: 

    NULL;

device.web_info.hostname: 

    NULL

## event ##

event_dimensions.hostname: 
    NULL

event_name: 

    level_complete, level_reset, level_end_quickplay, level_reset_quickplay, level_fail_quickplay,
    level_start, level_end, level_retry_quickplay, level_start_quickplay, level_up, level_fail, level_retry,
    level_complete_quickplay, completed_5_levels

    in_app_purchase, spend_virtual_currency , ad_reward , use_extra_steps, no_more_extra_steps

    firebase_campaign, dynamic_link_app_open, dynamic_link_first_open

    first_open, session_start, user_engagement, screen_view, select_content, challenge_accepted, challenge_a_friend, post_score   

    app_update, app_remove, app_clear_data, os_update, app_exception, error, notification_foreground

event_params.key:

    firebase_screen, firebase_screen_class, firebase_screen_id, firebase_previous_screen, firebase_previous_class, firebase_previous_id

    level, level_name, board, score

    product_id, product_name, price, currency, quantity, value, virtual_currency_name, ad_unit_code, ad_event_id

    dynamic_link_link_id, dynamic_link_link_name, dynamic_link_accept_time

    campaign, source, medium, term, gclid, content, item_id, item_name, content_type, type, firebase_conversion , firebase_event_origin

    message_name, message_id, message_time, message_device_time, click_timestamp

    firebase_error, error_value, fatal, validated

    previous_app_version, previous_os_version, previous_first_open_count, system_app_update, system_app, update_with_analytics

    timestamp, time, engagement_time_msec

event_params.value:

    string_value;

    int_value;

    float_value;

    double_value
    
event_previous_timestamp: 

    1982-01-01 08:23:23.376003 UTC - 2018-11-23 22:01:14.874004 UTC

event_server_timestamp_offset: 

    -5 001 183.669702 - 1 532 286 114.50615 секунд

    median: 0.494101 секунд
    p90: 2.34136 секунд
    p95: 5.505723 секунд
    p99: 36.202637 секунд

event_timestamp: 

    2018-06-12 07:00:10.908005 UTC - 2018-10-04 07:01:23.482000 UTC

event_value_in_usd: 

    0.919251 - 1.99, null-значение

## geo ##

geo.continent: 

    Americas, Asia, (not set), Europe, Africa, Oceania

geo.country: 
    Germany, Netherlands, Puerto Rico, South Korea, Turkey, Ireland, Philippines, Malaysia, Lithuania, Sri Lanka, Senegal, Jamaica, Cyprus, Uzbekistan, Libya, Japan, Belgium, Pakistan, Dominican Republic, China, France, Iran, Bangladesh, Zimbabwe, Uganda, Mauritius, Portugal, Bahamas, Namibia, Andorra, St. Lucia, Central African Republic, Guernsey, Israel, Serbia, Nigeria, South Africa, Jordan, Argentina, Afghanistan, Italy, Peru, Tunisia, Venezuela, Northern Mariana Islands, Guadeloupe, Chile, Kuwait, Ukraine, Latvia, Iceland, Cayman Islands, Nicaragua, Australia, Colombia, Spain, Romania, Slovenia, New Zealand, Slovakia, Laos, Cambodia, Aruba, Macau, Papua New Guinea, Brunei, Denmark, Vietnam, Hungary, Costa Rica, Honduras, Bolivia, Bosnia & Herzegovina, Armenia, Austria, Thailand, Sweden, Croatia, Saudi Arabia, Singapore, Qatar, U.S. Virgin Islands, Iraq, Yemen, Azerbaijan, Czechia, Macedonia (FYROM), Nepal, Myanmar (Burma), Kazakhstan, French Polynesia, Uruguay, Malta, French Guiana, Mexico, United States, Canada, Mongolia, Zambia, Caribbean Netherlands, Oman, Chad, Russia, Egypt, Morocco, Guam, Norway, Trinidad & Tobago, Ecuador, Bahrain, Haiti, Belize, Mozambique, Georgia, Gibraltar, Brazil, India, Greece, Kenya, Belarus, Guatemala, Panama, Syria, Botswana, Palestine, Ethiopia, Sudan, St. Pierre & Miquelon, United Arab Emirates, Taiwan, Switzerland, Algeria, Tanzania, Martinique, Finland, Luxembourg, El Salvador, Angola, Bermuda, Cape Verde, New Caledonia, United Kingdom, Indonesia, Hong Kong, Lebanon, Poland, Bulgaria, Côte d’Ivoire, Ghana, Montenegro, Estonia, Cameroon, Turkmenistan, Faroe Islands, ''

geo.region: 

    Pennsylvania, Osaka Prefecture, Karnataka, Texas, Aichi Prefecture, Massachusetts, Alabama, New South Wales, Hawaii, Kansas, Wisconsin, New York, District of Columbia, Nevada, Nebraska, Tokyo, South Australia, Tel Aviv District, Taipei City, Georgia, Tamil Nadu, Ile-de-France, Maharashtra, Mexico City, Colorado, Queensland, Ohio, Quebec, Kanagawa Prefecture, Indiana, Arizona, Arkansas, Illinois, California, Washington, North Carolina, Tennessee, Victoria, Telangana, England, Oregon, Missouri, Minnesota, Ontario, Utah, Delhi, Alberta, New Jersey, Hamburg, null, ''

geo.city: 

    Seattle, Indianapolis, Pune, Austin, Calgary, Toronto, Philadelphia, Washington, London, San Diego, Little Rock, Nagoya, San Jose, Boston, Denver, Sydney, Chicago, San Francisco, Dallas, New York, Plano, Sacramento, Adelaide, Hyderabad, Portland, Atlanta, Minneapolis, San Antonio, Phoenix, Parsippany-Troy Hills, Irving, Houston, Shinjuku, Madison, Hamburg, Montreal, Tel Aviv-Yafo, Charlotte, Melbourne, Omaha, New Delhi, Brisbane, Hope Hull, Cincinnati, Minato, Bengaluru, Osaka, Los Angeles, Salt Lake City, Overland Park, Paris, Nashville, Columbus, Mexico City, Chennai, Yokohama, Honolulu, St. Louis, Mumbai, null, ''

geo.sub_continent:

    South America, Eastern Asia, Western Europe, Eastern Africa, Northern Europe, Caribbean, Southeast Asia, Australasia, Southern Africa, Central America, Eastern Europe, Middle Africa, Northern America, Southern Europe, Western Asia, Central Asia, Southern Asia, (not set), null

geo.metro:
    null, (not set)

## tech ##

platform

    ANDROID, IOS

stream_id:

    1051193346, 1051193347
    

## traffic_source ## 

traffic_source.name:

    Mobile App | US | en | Mobile | Display Android | Flood It (Платная реклама), Mobile App | US | en | Mobile | Display iOS | Flood It (Платная реклама), Mobile App | US | en | Mobile | UAC Android | Flood It (UAC), FloodItAndroid_Feb2017, spring_sale, Invite a Friend (реферальная программа), (direct) (прямой поток)

traffic_source.medium: 

    dynamic_link, rj, cpc, organic, notification, invite_a_friend_campaign, graphic, (none), null

traffic_source.source: 

    Google, rj, google, invite_a_friend, firebase, (direct), null, AppLovin, google-play, Firebase

user_first_touch_timestamp:

    1970-02-08 23:06:34.034000 UTC - 2018-10-04 06:48:36.971000 UTC

## user ##

user_id:

    null-значение


user_ltv.revenue:

    диапазон значений 0.919251 - 7.20568

user_ltv.currency: 

    USD, null-значения


user_properties.key:

    _ltv_название валюты (AED, AUD, CHF, DKK, EUR, GBP, JPY, MXN, PKR, RON, SEK, TWD, USD),

    ad_frequency,

    firebase_exp_1, firebase_exp_3, firebase_exp_4, firebase_exp_5, firebase_exp_7

    firebase_last_notification

    first_open_time

    initial_extra_steps, num_levels_available, plays_progressive, plays_quickplay

user_properties.value:

    string_value;

    int_value;

    float_value;

    double_value;

    set_timestamp_micros

user_pseudo_id:

    уникальных значений 15175