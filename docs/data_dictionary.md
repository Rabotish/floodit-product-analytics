# Data Dictionary

Источник: `firebase-public-project.analytics_153293282.events_*`

Документ содержит физическую структуру источника: 
- уровни вложенности; 
- поля; 
- типы данных; 
- описание объектов верхнего уровня.

## Схема данных

| 1 уровень | 2 уровень | 3 уровень | 4 уровень |
|---|---|---|---|
| events_* | | | |
| | app_info (STRUCT) | id (STRING) | |
| | | version (STRING) | |
| | | install_store (STRING) | |
| | | firebase_app_id (STRING) | |
| | | install_source (STRING) | |
| | device (STRUCT) | category (STRING) | |
| | | mobile_brand_name (STRING) | |
| | | mobile_model_name (STRING) | |
| | | mobile_marketing_name (STRING) | |
| | | mobile_os_hardware_model (STRING) | |
| | | operating_system (STRING) | |
| | | operating_system_version (STRING) | |
| | | vendor_id (STRING) | |
| | | advertising_id (STRING) | |
| | | language (STRING) | |
| | | is_limited_ad_tracking (STRING) | |
| | | time_zone_offset_seconds (INT64) | |
| | | browser (STRING) | |
| | | browser_version (STRING) | |
| | | web_info (STRUCT) | browser (STRING) |
| | | | browser_version (STRING) |
| | | | hostname (STRING) |
| | event_bundle_sequence_id (INT64) | | |
| | event_date (STRING) | | |
| | event_dimensions (STRUCT) | hostname (STRING) | |
| | event_name (STRING) | | |
| | event_params (ARRAY<STRUCT>) | key (STRING) | |
| | | value (STRUCT) | string_value (STRING) |
| | | | int_value (INT64) |
| | | | float_value (FLOAT64) |
| | | | double_value (FLOAT64) |
| | event_previous_timestamp (INT64) | | |
| | event_server_timestamp_offset (INT64) | | |
| | event_timestamp (INT64) | | |
| | event_value_in_usd (FLOAT64) | | |
| | geo (STRUCT) | continent (STRING) | |
| | | country (STRING) | |
| | | region (STRING) | |
| | | city (STRING) | |
| | | sub_continent (STRING) | |
| | | metro (STRING) | |
| | platform (STRING) | | |
| | stream_id (STRING) | | |
| | traffic_source (STRUCT) | name (STRING) | |
| | | medium (STRING) | |
| | | source (STRING) | |
| | user_first_touch_timestamp (INT64) | | |
| | user_id (STRING) | | |
| | user_ltv (STRUCT) | revenue (FLOAT64) | |
| | | currency (STRING) | |
| | user_properties (ARRAY<STRUCT>) | key (STRING) | |
| | | value (STRUCT) | string_value (STRING) |
| | | | int_value (INT64) |
| | | | float_value (FLOAT64) |
| | | | double_value (FLOAT64) |
| | | | set_timestamp_micros (INT64) |
| | user_pseudo_id (STRING) | | |

 **Таблицы events_***: одна строка одной таблицы - одно событие пользователя. Таблиц 114 в диапазоне с 12 июня 2018 до 3 октября 2018 года, дата в названии таблиц указана в формате YYYYMMDD.

**app_info** - информация о приложении

**Атрибуты app_info:** 

    id;

    version - версия

    install_store - магазин, через который установлено приложение

    firebase_app_id - id приложения в Firebase;

    install_source - источник установки

**device** - устройство

**Атрибуты device:**

    category - категория

    mobile_brand_name - производитель. Not available in demo dataset

    mobile_model_name - модель. Not available in demo dataset

    mobile_marketing_name - маркетинговое название модели. Not available in demo dataset

    mobile_os_hardware_model - аппаратная модель. Not available in demo dataset

    operating_system - операционная система

    operating_system_version - версия операционной системы. Not available in demo dataset

    vendor_id - идентификатор от производителя

    advertising_id - рекламный идентификатор

    language - язык

    is_limited_ad_tracking - ограничение рекламного отслеживания

    time_zone_offset_seconds - смещение часового пояса относительно UTC

    browser - браузер *представлен не для всех дейли таблиц

    browser_version - версия браузера *представлен не для всех дейли таблиц

    web_info - информация о web-окружении *представлен не для всех дейли таблиц


**event_bundle_sequence_id** - порядковый номер пакета событий, отправленного Firebase

**event_date** - дата события YYYYMMDD

**event_dimensions.hostname** - hostname, связанный с событием

**event_name** - название события 

**event_params** - массив параметров конкретного события

**Атрибуты event_params:** 

    key - название параметра события
    
    value - значение параметра события:

        string_value;

        int_value;

        float_value;

        double_value
    
**event_previous_timestamp** - время предыдущего события пользователя. Время события в формате Unix timestamp в микросекундах

**event_server_timestamp_offset** - разница между временем устройства и временем сервера. Время события в формате Unix timestamp в микросекундах

**event_timestamp** - точное время события. Время события в формате Unix timestamp в микросекундах

**event_value_in_usd** - денежное значение события в долларах

**geo** - информация о геолокации пользователя игры

**Атрибуты geo:**

    continent - континент

    country - страна

    region - регион

    city - город

    sub_continent - субконтинент, атрибут представлен не во всех дейли таблицах

    metro - зона метрополитена, атрибут представлен не во всех дейли таблицах

**platform** - платформа пользователя

**stream_id** - идентификатор потока данных Firebase

**traffic_source** - источник привлечения

**Атрибуты traffic_source:**

    name - название кампании

    medium - тип канала

    source - источник привлечения

**user_first_touch_timestamp** - время первого взаимодействия пользователя с приложением

**user_id**  - id пользователя

**user_ltv** - LifeTime Value пользователя (накопленная ценность за жизненный цикл пользования приложением)

**Атрибуты user_ltv**:
    
    revenue - выручка

    currency - валюта

**user_properties** - характеристики отдельного пользователя

**Атрибуты user_properties:**

    key - название свойства пользователя

    value - значение определенного свойства:

        string_value;

        int_value;

        float_value;

        double_value;

        set_timestamp_micros


**user_pseudo_id** - анонимный идентификатор пользователя Firebase

