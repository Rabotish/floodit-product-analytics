# Event catalog #

**Решение вынести описание событий в отдельный документ обусловлено структурой данных, а именно одна строка - одно событие, подробное описание позволит разделить события на группы и удобно восстанавливать пользовательский сценарий, что способствует упрощению анализа.**

События сгруппированы по назначению:
- gameplay;
- monetization;
- acquisition;
- system;
- user interaction

## Группировка событий

События разделены по назначению:

| Группа | Описание |
|---|---|
| Gameplay | Игровые действия пользователя: начало, завершение, проигрыш, повторная попытка, сброс уровня, переход между уровнями |
| Monetization | События, связанные с внутриигровыми покупками, рекламой и использованием дополнительных ресурсов |
| Acquisition | События, связанные с источниками привлечения пользователей и рекламными кампаниями |
| User interaction | События, отражающие взаимодействие пользователя с приложением и игровым контентом |
| System | Технические события приложения и устройства |

## Gameplay events

| event_name | Назначение |
|---|---|
| `level_start` | Начало игровой попытки в основном режиме |
| `level_complete` | Успешное завершение уровня в основном режиме |
| `level_fail` | Неуспешное завершение уровня в основном режиме |
| `level_retry` | Повторная попытка прохождения уровня в основном режиме |
| `level_reset` | Сброс текущего уровня в основном режиме |
| `level_end` | Завершение игровой попытки в основном режиме |
| `level_up` | Переход пользователя на новый уровень |
| `level_start_quickplay` | Начало игровой попытки в Quickplay режиме |
| `level_complete_quickplay` | Успешное завершение игры в Quickplay режиме |
| `level_fail_quickplay` | Неуспешное завершение игры в Quickplay режиме |
| `level_retry_quickplay` | Повторная попытка в Quickplay режиме |
| `level_reset_quickplay` | Сброс игры в Quickplay режиме |
| `level_end_quickplay` | Завершение игры в Quickplay режиме |
| `completed_5_levels` | Достижение пользователем пятого уровня |
| `post_score` | Отправка игрового результата |

## Monetization events

| event_name | Назначение |
|---|---|
| `in_app_purchase` | Покупка внутри приложения |
| `spend_virtual_currency` | Использование игровой валюты |
| `ad_reward` | Получение награды за просмотр рекламы |
| `use_extra_steps` | Использование дополнительных ходов |
| `no_more_extra_steps` | Отсутствие доступных дополнительных ходов |

## Acquisition events

| event_name | Назначение |
|---|---|
| `firebase_campaign` | Событие, связанное с Firebase-кампаниями |
| `dynamic_link_app_open` | Открытие приложения через Firebase Dynamic Link |
| `dynamic_link_first_open` | Первое открытие приложения через Firebase Dynamic Link |

## User interaction events

| event_name | Назначение |
|---|---|
| `first_open` | Первое открытие приложения пользователем |
| `session_start` | Начало пользовательской сессии |
| `user_engagement` | Взаимодействие пользователя с приложением |
| `screen_view` | Просмотр экрана приложения |
| `select_content` | Выбор пользователем контента |
| `challenge_accepted` | Принятие пользовательского вызова |
| `challenge_a_friend` | Отправка вызова другу |

## System events

| event_name | Назначение |
|---|---|
| `app_update` | Обновление приложения |
| `app_remove` | Удаление приложения |
| `app_clear_data` | Очистка данных приложения |
| `os_update` | Обновление операционной системы |
| `app_exception` | Ошибка приложения |
| `error` | Ошибка Firebase/приложения |

## Pivot Table ##

| event_name | Назначение | Основные параметры |
|---|---|---|
| `level_start` | Начало игровой попытки в основном режиме | `level`, `level_name`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_complete` | Успешное завершение уровня в основном режиме | `level`, `level_name`, `value`, `firebase_screen_class`, `firebase_screen_id`, `firebase_conversion`, `firebase_event_origin` |
| `level_fail` | Неуспешное завершение уровня в основном режиме | `level`, `level_name`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_retry` | Повторная попытка прохождения уровня в основном режиме | `level`, `level_name`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_reset` | Сброс текущего уровня в основном режиме | `level`, `level_name`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_end` | Завершение игровой попытки в основном режиме | `level`, `level_name`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_up` | Переход пользователя на новый уровень | `level`, `level_name`, `value`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_start_quickplay` | Начало игровой попытки в Quickplay режиме | `board`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_complete_quickplay` | Успешное завершение игры в Quickplay режиме | `board`, `value`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_fail_quickplay` | Неуспешное завершение игры в Quickplay режиме | `board`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_retry_quickplay` | Повторная попытка в Quickplay режиме | `board`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_reset_quickplay` | Сброс игры в Quickplay режиме | `board`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `level_end_quickplay` | Завершение игры в Quickplay режиме | `board`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `completed_5_levels` | Достижение пользователем пятого уровня | `level`, `level_name`, `value`, `firebase_screen_class`, `firebase_screen_id`, `firebase_conversion`, `firebase_event_origin` |
| `in_app_purchase` | Покупка внутри приложения | `product_id`, `product_name`, `price`, `currency`, `quantity`, `value`, `validated`, `firebase_conversion`, `firebase_event_origin` |
| `spend_virtual_currency` | Использование игровой валюты | `virtual_currency_name`, `value`, `firebase_event_origin` |
| `ad_reward` | Получение награды за просмотр рекламы | `ad_unit_code`, `ad_event_id`, `type`, `value`, `firebase_screen_class`, `firebase_screen_id`, `firebase_event_origin` |
| `use_extra_steps` | Использование дополнительных ходов | параметры не определены в исследованных данных |
| `no_more_extra_steps` | Отсутствие доступных дополнительных ходов | параметры не определены в исследованных данных |
| `firebase_campaign` | Событие Firebase-кампании | `campaign`, `source`, `medium`, `term`, `gclid`, `content` |
| `dynamic_link_app_open` | Открытие приложения через Firebase Dynamic Link | `dynamic_link_link_id`, `dynamic_link_link_name`, `dynamic_link_accept_time` |
| `dynamic_link_first_open` | Первое открытие приложения через Firebase Dynamic Link | `dynamic_link_link_id`, `dynamic_link_link_name`, `dynamic_link_accept_time` |
| `first_open` | Первое открытие приложения пользователем | `firebase_conversion`, `firebase_event_origin`, параметры экрана |
| `session_start` | Начало пользовательской сессии | `firebase_conversion`, `firebase_event_origin`, параметры экрана |
| `user_engagement` | Взаимодействие пользователя с приложением | параметры экрана |
| `screen_view` | Просмотр экрана приложения | параметры экрана |
| `select_content` | Выбор пользователем контента | `content_type`, `item_id`, `item_name` |
| `challenge_accepted` | Принятие пользовательского вызова | параметры не определены в исследованных данных |
| `challenge_a_friend` | Отправка вызова другу | параметры не определены в исследованных данных |
| `post_score` | Отправка игрового результата | `score` |
| `app_update` | Обновление приложения | `previous_app_version`, `previous_os_version`, `previous_first_open_count`, `system_app_update`, `system_app`, `update_with_analytics` |
| `app_remove` | Удаление приложения | параметры не определены в исследованных данных |
| `app_clear_data` | Очистка данных приложения | параметры не определены в исследованных данных |
| `os_update` | Обновление операционной системы | параметры не определены в исследованных данных |
| `app_exception` | Ошибка приложения | `fatal` |
| `error` | Ошибка Firebase/приложения | `firebase_error`, `error_value` |


**Ниже представлен более подробный обзор и взаимосвязи, к которым можно обратиться при необходимости**

## Обзор существующих событий ##

**event_name** - название события

Названия событий поделю на: 

    level_ (Игровые события) : 

        level_complete - уровень пройден,
        
        level_reset - сбросить текущий результат прохождения уровня без его завершения,
        
        level_end_quickplay - завершен уровень в режиме quickplay,
        
        level_reset_quickplay - сбросить текущий результат прохождения уровня без его завершения в режиме quickplay,
        
        level_fail_quickplay - поражение в режиме quickplay,

        level_start - начат уровень,
        
        level_end - уровень завершен,
        
        level_retry_quickplay - повторение попытки пройти уровень в режиме quickplay,
        
        level_start_quickplay - начало прохождения уровня в режиме quickplay,
        
        level_up - пока хз, полагаю, что начало нового уровня после выигрыша
        
        level_fail - поражение,
        
        level_retry - повторение попытки пройти уровень,

        level_complete_quickplay - победа в режиме quickplay,
        
        completed_5_levels - успешно пройдено 5 уровней

    IAP (Внутриигровая монетизация):

        in_app_purchase - произошла покупка внутри приложения,
        
        spend_virtual_currency - потрачена игровая валюта,
        
        ad_reward - начислена награда за рекламу,
        
        use_extra_steps - использованы доп ходов,
        
        no_more_extra_steps - закончились доп ходы

    Ads (Внешняя монетизация):

        firebase_campaign - событие, связанное с Firebase-кампаниями,
        
        dynamic_link_app_open - открытие приложения через Firebase Dynamic Link,
        
        dynamic_link_first_open - хз, но наверно первое открытие приложения через Firebase Dynamic Link

    Actions_us (Пользовательская активность):

        first_open - первое открытие приложения,
        
        session_start - начата сессия,
        
        user_engagement - хз,
        
        screen_view - хз,
        
        select_content - выбран контент,
        
        challenge_accepted - принят вызов,
        
        challenge_a_friend - хз, но наверно поступление вызова от друга,
        
        post_score - поделиться счетом

    System (Системные события):

        app_update - обновление приложения,
        
        app_remove - удаление приложения,
        
        app_clear_data - очиститка данных приложения,
        
        os_update - обновление операционной системы,
        
        app_exception - выброс исключения приложением,
        
        error - какая-то пока неустановленная ошибка


**event_params** - массив параметров конкретного события

Существующие параметры событий поделены на:

    firebase_ (навигация и экраны): 

        firebase_screen - название текущего экрана, 

        firebase_screen_class - класс экрана,

        firebase_screen_id - id экрана,

        firebase_previous_screen - название предыдущего экрана,

        firebase_previous_class - класс предыдущего экрана,

        firebase_previous_id - id предыдущего экрана

    gameplay_param (игровые парметры):
    
        level - уровень,
        
        level_name - название уровня,
        
        board - размер игровой доски,
        
        score - счет

    IAP_param (внутренние покупки):
    
        product_id - id платного игрового продукта,
    
        product_name - название платного игрового продукта,
        
        price - цена,
        
        currency - валюта,
        
        quantity - количество,
        
        value - величина,
        
        virtual_currency_name - название игровой валюты,
        
        ad_unit_code - идентификатор рекламного блока,
        
        ad_event_id - id рекламного события

    dynamic_link (Firebase Dynamic Links): 
    
        dynamic_link_link_id - id ссылки,
        
        dynamic_link_link_name - название ссылки,
        
        dynamic_link_accept_time - время принятия ссылки

    ads_param/content (параметры внешней рекламы / внутреннего контента):
    
        campaign - название рекламной кампании,
        
        source - источник трафика,
        
        medium - канал,
        
        term - ключевое слово рекламной кампании,
        
        gclid - Google Click ID,
        
        content - доп параметр кампании,
        
        item_id - универсальный идентификатор выбранного игрового объекта,
        
        item_name - название уровня
        
        content_type - категория выбранного контента,
        
        type - тип внутриигрового элемента,
        
        firebase_conversion - признак конверсии Firebase,
        
        firebase_event_origin - источник создания события

    message (сообщения пользователю): 
        
        message_name - название сообщения,
        
        message_id - id сообщения,
        
        message_time - время отправки сообщения,
        
        message_device_time - время получения сообщения устройством,
        
        click_timestamp - время перехода по уведомлению

    errors (ошибки):
    
        firebase_error - код ошибки Firebase,
    
        error_value - значение ошибки,
    
        fatal - критичная ошибка,
    
        validated - валидация

    version (версии):

        previous_app_version - предыдущая версия приложения, 
        
        previous_os_version - предыдущая версия операционной системы,
        
        previous_first_open_count - предыдущее значение счётчика события first_open, переданное Firebase SDK,
        
        system_app_update - обновление системы приложения,
        
        system_app - признак системного приложения,
        
        update_with_analytics - обновление с учетом аналитики

    time:
    
        timestamp - временная метка события,
    
        time - хз, наверно тоже

## Связка event_param.key и event_param.value ##

**В этом блоке приведены связки конкретных значений, относящихся к выше перечисленным событиям и хранящиеся в одном event_param**

**Если перечислены не все варианты структуры event_param.value, значит в наборе данных они представлены в виде NULL-значения и опущены при рассмотрении.**
    
**firebase_screen.value:**

    Значение типа <экран приложения>/<тип рекламы>, представлены два типа рекламы - межстраничная Interstitial и вознаграждаемая Rewarded, для упрощения в дальнейшем опишу только предполагаемый экран размещения рекламы

    string_value:
    
        FIGameViewController/Interstitial - экран игрового процесса,
        
        FIRootViewController/Interstitial - главный контроллер приложения,
        
        game_over/Interstitial - экран окончания игры,
        
        main_menu/Interstitial, - главное меню
        
        out_of_steps/Interstitial - экран отсутствия ходов,
        
        game_board/Interstitial  - игровое поле,

        extra_steps/Rewarded - экран получения дополнительных ходов,

        UIAlertController/Rewarded - системное диалоговое окно iOS

**firebase_screen_class.value:**

    Представлены значения классов текущего экрана

    string_value:

    Основные экраны приложения: 
    
        main_menu - главное меню,

        FIMainMenuViewController - контроллер главного меню приложения,

        MainMenuActivity - активность главного меню приложения,

        game_board - игровое поле,

        FIGameViewController - контроллер игрового процесса,

        FloodItActivity - активность игры Flood It,

        game_over - окончание игры,

        FIGameOverViewController - контроллер экрана окончания игры,

        GameFinishedActivity - активность завершения игры,

        out_of_steps - отсутствие ходов,

        FIOutOfStepsViewController - контроллер экрана отсутствия ходов,

        extra_steps - дополнительные ходы,

        ExtraStepsActivity - активность дополнительных ходов,

        FIGetMoreStepsTableViewController - контроллер таблицы получения дополнительных ходов,

        level_select - выбор уровня,

        LevelSelectionActivity - активность выбора уровня,

        FILevelsCollectionViewController - контроллер коллекции уровней,

        how_to_play - как играть,

        FIHowToPlayViewController - контроллер инструкции по игре,

        stats - статистика,

        FIStatisticsViewController - контроллер статистики,

        settings - настройки,

        SettingsActivity - активность настроек,

        FIOptionsViewController - контроллер настроек приложения,

        AboutActivity - активность информации о приложении,

        iap - внутренняя покупка,

        shop_menu - меню магазина

    Экраны монетизации и рекламы: 

        GADOInterstitialViewController - контроллер межстраничной рекламы GADO,

        GADInterstitialViewController - контроллер межстраничной рекламы Google AdMob,

        GADNFullScreenAdViewController - контроллер полноэкранной рекламы GADN,

        GADBrowserViewController - контроллер браузера рекламы GAD,

        GADOBrowserViewController - контроллер браузера рекламы GADO,

        GADNBrowserViewController - контроллер браузера рекламы GADN,

        AdActivity - активность рекламы,

        AdUnitActivity - активность рекламного блока,

        FIAdViewController - контроллер просмотра рекламы Flood It,

        MraidActivity - активность MRAID рекламы,

        MraidVideoPlayerActivity - активность видеоплеера MRAID рекламы,

        MPAdBrowserController - контроллер браузера рекламы MoPub,

        MoPubActivity - активность рекламы MoPub,

        MoPubBrowser - браузер рекламы MoPub,

        FlurryFullscreenTakeoverActivity - активность полноэкранной рекламы Flurry,

        WebFullScreenVideoRootViewController - корневой контроллер полноэкранного веб-видео,

        MRExpandModalViewController - контроллер расширенного модального окна рекламы

    Системные и технические экраны:

        UIApplicationRotationFollowingController - контроллер управления поворотом приложения,

        _UIModalItemsPresentingViewController - контроллер отображения модальных элементов,

        UIViewController - базовый контроллер интерфейса iOS,

        UIAlertController - системный контроллер диалоговых окон iOS,

        WKActionSheet - системное меню действий WebKit,

        WKSelectTableViewController - контроллер выбора WebKit,

        SFSafariViewController - контроллер встроенного браузера Safari

    Технические/неопределённые:

        FIRootViewController - корневой контроллер приложения Firebase,

        DDParsecNoDataViewController - контроллер отсутствия данных DDParsec,

        MPiOS7SafeStoreProductViewController - контроллер страницы продукта магазина MoPub/iOS 7,

        GADNDebugOptionsViewController - контроллер отладочных настроек GADN

**firebase_screen_id.value:**
    
    Представлено описание значений id текущего экрана

    int_value / float_value, если отсутствует int_value, то id записан через float_value

**level.value:** 

    Описание значений параметра уровень

    int_value / double_value в диапазоне от 0 до 31

**level_name.value:** 

    Описание значений параметра название уровня

    string_value: level_1-31

**board.value:**

    Описание параметра поле

    string_value: M, S, L

**score.value:** 

    Описание параметра счет

    int_value / double_value в диапазоне от 0 до 21

**product_id.value:**

    Описание айди платного игрового продукта

    string_value: extra_steps_pack_1, extra_steps_pack_2, extra_steps_pack_3, remove_ads

**product_name.value:**

    Описание названия платного игрового продукта

    string_value: Remove Ads, Extra Steps Pack 1, Extra Steps Pack 3, ''

**price.value:**

    int_value в диапазоне от 990000 до 120000000 *требует уточнения 

**currency.value:** 
    
    string_value: JPY, USD, AUD, TWD, AED, DKK, CHF

**quantity:** 

    int_value: 1

**value.value:** 

    int_value / double_value в основном в диапазоне от 0 до 49  есть экстремально большие значения *требуется уточнение

**virtual_currency_name.value:**
    
    string_value: steps

**ad_unit_code:**

    string_value: ca-app-pub-8123415297019784/8583475532, ca-app-pub-8123415297019784/9501821136

**ad_event_id:**

    int_value

**dynamic_link_link_id:** 

Результат представлен в виде 6 ссылок

    string_value

**dynamic_link_link_name.value:**

    string_value: Invite a Friend


**dynamic_link_accept_time.value:**

     int_value

**campaign.value:** 

    string_value: '', Invite a Friend, spring_sale

**source.value:** 
    
    string_value: (not set), google-play, invite_a_friend, Google, google, firebase

**medium.value:** 

    string_value: invite_a_friend_campaign, (not set), cpc, organic, dynamic_link

**term.value:** 

    string_value: running+shoes, flood.apk, flood it, download flood it, fb flooding app download, flood it 2 game, flood it game, com.labpixies.flood, color flood, app para criar flood, floodit

**gclid.value:**

     string_value

**content.value:**

     string_value: logolink

**item_id.value:**

    string_value: числа от 1 до 30, игровые режимы Quickplay, quickplay, Progressive, progressive, внутренние покупки extra_steps_1, extra_steps_2, extra_steps_3, remove_ads, размер поля S, M, L

**item_name.value:**

    string_value: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20, 24, 25, 26, 27, 28, 29, 30

**content_type.value:** 

    string_value: mode, level, board, IAP
    
**type.value:** 

    string_value: '', Steps
    
**firebase_conversion.value:**

    int_value: 1
    
**firebase_event_origin.value:**

    string_value: clx, crash, am, app+gtm, fdl, auto, fdl+gtm, app, fcm

**message_name.value:**

    string_value: Mid-Week Challenge
    
**message_id.value:**
    
    string_value: 4103780380169369052
    
**message_time.value:**

    int_value: 1490814000
    
**message_device_time.value:**

    string_value: 1
    
**click_timestamp.value:**

    int_value

**firebase_error.value:**

    int_value: 13
    
**error_value.value:**

    string_value: ad_click
    
**fatal.value:**

    int_value: 1
    
**validated.value:**

    int_value: 1

**previous_app_version.value:**

    string_value: значения не везде соотносятся с app_info.version
    
**previous_os_version.value:**

    string_value
    
**previous_first_open_count.value:**

    int_value (12 уникальных значений)
    
**system_app_update.value:**

    int_value: 0
    
**system_app.value:**

    int_value: 0
    
**update_with_analytics.value:**

    int_value: 0, 1

**timestamp.value:**

    int_value (5140 уникальных значений)
    
**time.value:**

 int_value / float_value значения представлены 1 и 1.0 (Null-значения присутствуют в обоих атрибутах, но не одновременно)

## user_properties ##

Массив user_properties представляет собой характеристики отдельного пользователя

user_properties.key:

Представленные характеристики были поделены по логике на:

    _ltv_название валюты (AED, AUD, CHF, DKK, EUR, GBP, JPY, MXN, PKR, RON, SEK, TWD, USD) - накомпленная выручка в определенной валюте,

    ad_frequency - показатель частоты показа рекламы,

    firebase_exp_1, firebase_exp_3, firebase_exp_4, firebase_exp_5, firebase_exp_7 - эксперименты Firebase / AB тесты, отображает принадлежность пользователя к эксперементальной группе,

    firebase_last_notification - последнне уведомление, направленное пользователю и связанное с ним,

    first_open_time - время первого открытия приложения пользователем,

    initial_extra_steps (количество дополнительных ходов, доступных пользователю изначально) , num_levels_available (количество доступных пользователю уровней), plays_progressive (имеет булево значение, отображает режим игры), plays_quickplay (имеет булево значение, отображает режим игры) - gameplay параметры

user_properties.value: - представляет собой структуру, которая хранит значения характеристик в различных типах данных

    string_value;

    int_value;

    float_value;

    double_value;

    set_timestamp_micros


## Связка user_properties.key и user_properties.value ##

**Как и в предыдущем блоке, если какое-либо значение ... .value.атрибут пропущено, значит в наборе данных оно представлено как NULL-значение**

**_ltv_название валюты.value:** 

    int_value и set_timestamp_micros

**ad_frequency.value:**

    string_value и set_timestamp_micros

**firebase_exp_номер эксперимента.value:**

    string_value (значения от 0 до 3) и set_timestamp_micros

**firebase_last_notification.value:**

    предположительно идентификатор/служебное значение последнего Firebase-уведомления пользователя
    string_value и set_timestamp_micros

**first_open_time.value:**

    int_value и set_timestamp_micros

**initial_extra_steps.value:**

    string_value (3, 5, 10, 20) и set_timestamp_micros 

**num_levels_available.value:**

    string_value: 30, set_timestamp_micros

**plays_progressive.value:**

    string_value: true, set_timestamp_micros

**plays_quickplay.value:**

    string_value: true, set_timestamp_micros

## Связь event_name и event_params.key ##

completed_5_levels:
firebase_screen_class, firebase_event_origin, firebase_screen_id, level_name, firebase_conversion, level, value

level_complete:
firebase_conversion, level, firebase_screen_class, firebase_screen_id, firebase_event_origin, value, level_name

level_complete_quickplay:
firebase_event_origin, firebase_screen_id, value, firebase_screen_class, board

level_end:
firebase_event_origin, firebase_screen_class, firebase_screen_id, level, level_name

level_end_quickplay:
firebase_screen_id, firebase_screen_class, firebase_event_origin, board

level_fail:
firebase_screen_class, level, firebase_event_origin, level_name, firebase_screen_id

level_fail_quickplay:
firebase_screen_class, firebase_screen_id, firebase_event_origin, board

level_reset:
level_name, level, firebase_screen_id, firebase_screen_class, firebase_event_origin

level_reset_quickplay:
firebase_event_origin, board, firebase_screen_id, firebase_screen_class

level_retry:
firebase_screen_class, level_name, level, firebase_event_origin, firebase_screen_id

level_retry_quickplay:
firebase_screen_class, firebase_event_origin, firebase_screen_id, board

level_start:
firebase_screen_class, firebase_event_origin, firebase_screen_id, level, level_name

level_start_quickplay:
firebase_screen_id, firebase_screen_class, board, firebase_event_origin

level_up:
level_name, value, firebase_event_origin, level, firebase_screen_class, firebase_screen_id

ad_reward:
firebase_screen_id, ad_unit_code, firebase_event_origin, type, firebase_screen, firebase_screen_class, value, ad_event_id

in_app_purchase:
firebase_conversion, validated, firebase_event_origin, firebase_screen_id, value, firebase_screen_class, price, product_name, quantity, product_id, currency

no_more_extra_steps:
firebase_screen_class, firebase_screen_id, value, firebase_event_origin

spend_virtual_currency:
firebase_screen_id, virtual_currency_name, firebase_screen_class, item_name, firebase_event_origin, value

use_extra_steps:
firebase_event_origin, virtual_currency_name, item_name, value, firebase_screen_id, firebase_screen_class

dynamic_link_app_open:
firebase_screen_id, medium, firebase_screen_class, dynamic_link_link_id, dynamic_link_link_name, campaign, source, firebase_event_origin, dynamic_link_accept_time

dynamic_link_first_open:
firebase_screen_class, dynamic_link_accept_time, source, medium, firebase_event_origin, campaign, dynamic_link_link_id, firebase_screen_id, dynamic_link_link_name

firebase_campaign:
campaign, click_timestamp, content, firebase_screen_class, gclid, term, firebase_event_origin, firebase_screen_id, source, medium

challenge_a_friend:
firebase_event_origin, firebase_screen_class, firebase_screen_id, board

challenge_accepted:
board, firebase_screen_id, firebase_screen_class, firebase_event_origin

first_open:
firebase_screen_id, firebase_screen_class, firebase_conversion, firebase_event_origin, system_app, system_app_update, firebase_screen, update_with_analytics, previous_first_open_count

post_score:
score, level, time, firebase_screen_class, firebase_event_origin, firebase_screen_id, level_name

screen_view:
firebase_previous_class, firebase_previous_screen, firebase_screen, firebase_event_origin, firebase_screen_id, firebase_previous_id, firebase_screen_class

select_content:
firebase_screen_class, firebase_event_origin, content_type, item_id, firebase_screen_id

session_start:
firebase_screen_id, firebase_screen_class, firebase_screen, firebase_conversion, firebase_event_origin

user_engagement:
firebase_screen_id, engagement_time_msec, firebase_screen, firebase_screen_class, firebase_event_origin

app_clear_data:
firebase_event_origin

app_exception:
fatal, firebase_screen_class, firebase_screen_id, firebase_event_origin, timestamp

app_remove:
firebase_event_origin

app_update:
firebase_screen_class, firebase_event_origin, firebase_screen_id, previous_app_version

error:
error_value, firebase_event_origin, firebase_screen_id, firebase_screen, firebase_screen_class, firebase_error

os_update:
previous_os_version, firebase_screen_id, firebase_event_origin, firebase_screen_class


**Связь event_name и user_properties.key**

completed_5_levels:
plays_progressive, _ltv_AUD, firebase_exp_1, firebase_exp_4, firebase_last_notification, _ltv_CHF, initial_extra_steps, _ltv_USD, first_open_time, _ltv_JPY, ad_frequency, firebase_exp_5, firebase_exp_3, plays_quickplay, num_levels_available, _ltv_TWD

level_complete:
plays_quickplay, _ltv_PKR, _ltv_CHF, firebase_exp_1, first_open_time, firebase_exp_3, _ltv_TWD, plays_progressive, _ltv_USD, initial_extra_steps, _ltv_DKK, firebase_last_notification, ad_frequency, firebase_exp_4, num_levels_available, _ltv_AUD, firebase_exp_5, _ltv_JPY

level_complete_quickplay:
plays_quickplay, _ltv_AED, ad_frequency, num_levels_available, _ltv_USD, plays_progressive, _ltv_JPY, _ltv_EUR, firebase_exp_5, _ltv_AUD, _ltv_CHF, firebase_exp_1, firebase_exp_4, first_open_time, firebase_exp_3, initial_extra_steps, firebase_last_notification, _ltv_GBP, _ltv_DKK

level_end:
firebase_exp_4, plays_progressive, firebase_exp_1, first_open_time, firebase_exp_3, _ltv_PKR, _ltv_CHF, plays_quickplay, _ltv_AUD, firebase_last_notification, _ltv_USD, firebase_exp_5, _ltv_DKK, _ltv_TWD, initial_extra_steps, num_levels_available, _ltv_JPY, ad_frequency

level_end_quickplay:
_ltv_USD, _ltv_EUR, firebase_exp_4, num_levels_available, _ltv_GBP, _ltv_JPY, _ltv_AED, plays_quickplay, plays_progressive, first_open_time, firebase_exp_3, initial_extra_steps, _ltv_CHF, firebase_exp_1, firebase_exp_5, _ltv_AUD, _ltv_DKK, ad_frequency, firebase_last_notification

level_fail:
ad_frequency, _ltv_USD, firebase_last_notification, firebase_exp_4, num_levels_available, plays_quickplay, _ltv_CHF, first_open_time, initial_extra_steps, firebase_exp_5, _ltv_PKR, firebase_exp_3, _ltv_DKK, _ltv_TWD, _ltv_JPY, plays_progressive, firebase_exp_1

level_fail_quickplay:
first_open_time, _ltv_JPY, firebase_exp_3, ad_frequency, plays_quickplay, _ltv_AED, _ltv_EUR, initial_extra_steps, firebase_last_notification, num_levels_available, firebase_exp_5, firebase_exp_4, _ltv_CHF, _ltv_DKK, plays_progressive, firebase_exp_1, _ltv_USD, _ltv_AUD, _ltv_GBP

level_reset:
ad_frequency, plays_quickplay, firebase_exp_4, plays_progressive, firebase_exp_5, _ltv_TWD, firebase_exp_1, firebase_last_notification, firebase_exp_3, _ltv_USD, _ltv_PKR, initial_extra_steps, _ltv_JPY, first_open_time, num_levels_available, _ltv_CHF

level_reset_quickplay:
first_open_time, ad_frequency, _ltv_USD, _ltv_PKR, firebase_exp_4, plays_progressive, firebase_last_notification, _ltv_EUR, _ltv_AUD, _ltv_JPY, initial_extra_steps, _ltv_GBP, firebase_exp_3, firebase_exp_5, _ltv_CHF, firebase_exp_1, num_levels_available, plays_quickplay, _ltv_AED

level_retry:
firebase_exp_4, _ltv_DKK, _ltv_AUD, firebase_last_notification, num_levels_available, _ltv_USD, firebase_exp_3, firebase_exp_1, _ltv_CHF, plays_progressive, initial_extra_steps, plays_quickplay, first_open_time, _ltv_PKR, firebase_exp_5, ad_frequency, _ltv_TWD, _ltv_JPY

level_retry_quickplay:
plays_quickplay, _ltv_GBP, firebase_exp_4, _ltv_USD, initial_extra_steps, _ltv_JPY, first_open_time, _ltv_AUD, firebase_exp_1, firebase_last_notification, firebase_exp_3, plays_progressive, ad_frequency, num_levels_available, _ltv_AED, firebase_exp_5, _ltv_CHF

level_start:
plays_quickplay, firebase_exp_3, _ltv_JPY, num_levels_available, _ltv_USD, _ltv_AUD, firebase_exp_1, firebase_exp_5, _ltv_TWD, _ltv_CHF, firebase_exp_4, plays_progressive, ad_frequency, firebase_last_notification, _ltv_PKR, initial_extra_steps, first_open_time, _ltv_DKK

level_start_quickplay:
plays_quickplay, num_levels_available, firebase_exp_5, _ltv_JPY, _ltv_AED, _ltv_MXN, initial_extra_steps, firebase_last_notification, first_open_time, _ltv_AUD, _ltv_GBP, ad_frequency, firebase_exp_3, _ltv_DKK, _ltv_EUR, firebase_exp_4, plays_progressive, _ltv_CHF, firebase_exp_1, _ltv_USD, _ltv_PKR

level_up:
initial_extra_steps, plays_quickplay, firebase_exp_5, first_open_time, _ltv_PKR, firebase_exp_3, firebase_exp_4, plays_progressive, firebase_exp_1, _ltv_TWD, _ltv_CHF, firebase_last_notification, _ltv_USD, _ltv_DKK, ad_frequency, _ltv_JPY, num_levels_available, _ltv_AUD

ad_reward:
ad_frequency, _ltv_USD, firebase_exp_3, initial_extra_steps, firebase_last_notification, _ltv_AED, num_levels_available, _ltv_DKK, plays_quickplay, first_open_time, firebase_exp_4, firebase_exp_1, plays_progressive

in_app_purchase:
plays_quickplay, firebase_exp_3, _ltv_JPY, initial_extra_steps, _ltv_USD, _ltv_TWD, num_levels_available, _ltv_AUD, ad_frequency, _ltv_DKK, firebase_exp_1, plays_progressive, _ltv_CHF, firebase_exp_4, first_open_time, _ltv_AED

no_more_extra_steps:
firebase_exp_3, firebase_exp_4, _ltv_DKK, firebase_exp_5, ad_frequency, plays_progressive, _ltv_AED, first_open_time, firebase_exp_1, plays_quickplay, firebase_last_notification, _ltv_USD, initial_extra_steps, num_levels_available

spend_virtual_currency:
firebase_exp_3, first_open_time, _ltv_DKK, ad_frequency, firebase_exp_4, plays_progressive, _ltv_GBP, initial_extra_steps, firebase_exp_1, plays_quickplay, _ltv_AED, firebase_exp_5, _ltv_USD, num_levels_available, firebase_last_notification

use_extra_steps:
ad_frequency, plays_quickplay, firebase_exp_4, _ltv_DKK, _ltv_GBP, num_levels_available, plays_progressive, _ltv_AED, _ltv_USD, first_open_time, firebase_exp_3, initial_extra_steps, firebase_exp_5, firebase_exp_1, firebase_last_notification

dynamic_link_app_open:
first_open_time, initial_extra_steps, ad_frequency, firebase_exp_4, plays_quickplay, num_levels_available, plays_progressive, firebase_exp_1

dynamic_link_first_open:
initial_extra_steps, firebase_exp_1, first_open_time, ad_frequency, num_levels_available

firebase_campaign:
firebase_exp_4, ad_frequency, initial_extra_steps, firebase_exp_1, first_open_time, num_levels_available, plays_quickplay, plays_progressive

challenge_a_friend:
firebase_exp_1, plays_quickplay, num_levels_available, firebase_exp_4, ad_frequency, initial_extra_steps, _ltv_JPY, first_open_time, firebase_last_notification, plays_progressive

challenge_accepted:
plays_progressive, firebase_exp_1, initial_extra_steps, plays_quickplay, num_levels_available, ad_frequency, first_open_time

first_open:
num_levels_available, plays_progressive, first_open_time

post_score:
_ltv_PKR, _ltv_AED, _ltv_GBP, firebase_exp_1, plays_quickplay, ad_frequency, _ltv_JPY, _ltv_DKK, first_open_time, firebase_exp_5, num_levels_available, initial_extra_steps, firebase_last_notification, firebase_exp_4, _ltv_AUD, _ltv_EUR, firebase_exp_3, plays_progressive, _ltv_USD, _ltv_CHF, _ltv_TWD

screen_view:
_ltv_USD, _ltv_TWD, firebase_last_notification, ad_frequency, firebase_exp_3, _ltv_CHF, firebase_exp_1, _ltv_EUR, firebase_exp_7, plays_progressive, first_open_time, _ltv_AED, _ltv_DKK, _ltv_JPY, _ltv_MXN, num_levels_available, plays_quickplay, initial_extra_steps, _ltv_SEK, firebase_exp_4, firebase_exp_5, _ltv_GBP, _ltv_AUD, _ltv_PKR

select_content:
num_levels_available, initial_extra_steps, _ltv_JPY, ad_frequency, plays_quickplay, _ltv_USD, _ltv_AUD, _ltv_PKR, _ltv_TWD, firebase_last_notification, _ltv_CHF, plays_progressive, firebase_exp_1, firebase_exp_4, _ltv_AED, firebase_exp_5, firebase_exp_3, _ltv_GBP, _ltv_EUR, first_open_time, _ltv_DKK, _ltv_MXN

session_start:
ad_frequency, _ltv_AED, firebase_exp_5, _ltv_DKK, _ltv_GBP, _ltv_AUD, num_levels_available, plays_progressive, plays_quickplay, firebase_exp_3, _ltv_PKR, _ltv_TWD, firebase_exp_4, first_open_time, firebase_exp_1, initial_extra_steps, firebase_last_notification, _ltv_JPY, _ltv_EUR, _ltv_MXN, _ltv_CHF, _ltv_USD

user_engagement:
firebase_last_notification, initial_extra_steps, firebase_exp_3, _ltv_EUR, _ltv_SEK, plays_quickplay, firebase_exp_1, first_open_time, ad_frequency, _ltv_CHF, num_levels_available, plays_progressive, _ltv_GBP, _ltv_JPY, _ltv_AED, _ltv_USD, _ltv_DKK, _ltv_PKR, _ltv_AUD, _ltv_TWD, firebase_exp_5, firebase_exp_4, _ltv_MXN

app_clear_data:
initial_extra_steps, firebase_exp_1, first_open_time, num_levels_available, plays_quickplay, plays_progressive, firebase_exp_4, ad_frequency

app_exception:
ad_frequency, firebase_exp_1, firebase_exp_4, initial_extra_steps, _ltv_JPY, num_levels_available, firebase_last_notification, plays_progressive, first_open_time, firebase_exp_3, plays_quickplay, firebase_exp_5, _ltv_USD

app_remove:
_ltv_GBP, firebase_exp_4, initial_extra_steps, firebase_exp_1, _ltv_JPY, ad_frequency, num_levels_available, _ltv_USD, plays_progressive, first_open_time, firebase_last_notification, _ltv_RON, plays_quickplay, firebase_exp_5

app_update:
plays_progressive, firebase_last_notification, _ltv_USD, _ltv_JPY, firebase_exp_3, _ltv_GBP, ad_frequency, plays_quickplay, num_levels_available, initial_extra_steps, first_open_time

error:
initial_extra_steps, plays_progressive, _ltv_USD, firebase_exp_3, first_open_time, plays_quickplay, ad_frequency, firebase_last_notification, num_levels_available

os_update:
_ltv_JPY, _ltv_GBP, plays_progressive, plays_quickplay, _ltv_AUD, firebase_exp_4, _ltv_EUR, num_levels_available, ad_frequency, firebase_last_notification, _ltv_USD, initial_extra_steps, firebase_exp_1, firebase_exp_5, first_open_time, firebase_exp_3