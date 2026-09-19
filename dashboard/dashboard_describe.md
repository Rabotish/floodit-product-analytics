# Dashboard

[**Открыть dashboard в Looker Studio**](https://datastudio.google.com/reporting/9a66c5fc-54da-495e-bf02-ba19d6be05c0)

## Pages

### 1. Product Health

Обзор основных продуктовых показателей раннего пользовательского пути:

- new users;
- first result reach;
- activation rate;
- retry rate;
- same-day return;
- D1 retention;
- D7 retention;
- динамика retention и activation;
- сравнение ключевых метрик между Android и iOS.

![Executive Product Health](/dashboard/screenshots/product_helth.png)

### 2. Activation & Early Journey

Обзор поведения пользователя до и после первого игрового результата:

- переход от new user к first result;
- activation после первого результата;
- success / fail первого результата;
- retry после первого fail;
- first-session result depth.

![Activation and Early Journey](/dashboard/screenshots/activation_and_early_journey.png)

### 3. Retention & Behavioural Segments

Обзор retention по ключевыми поведенческими сегментами:

- D1 / D7 retention;
- D1 retention по activation status;
- D1 retention по same-day return;
- retention по first result outcome;
- retention по first-session depth;
- различия между Android и iOS.

![Retention and Behavioural Segments](/dashboard/screenshots/retention_and_behavioural_segments.png)

## Data sources

Dashboard использует подготовленный BI-слой в Google BigQuery:

- `mart_dashboard_overview`;
- `mart_dashboard_early_journey`;
- `mart_dashboard_retention`.

Исходная аналитическая витрина для dashboard marts:

- `mart_user_early_journey`.

**Код для создания витрин:** [`sql/marts/`](/sql/marts/)

Rates в dashboard рассчитываются через отношение агрегированных числителей и знаменателей, например:

```text
D1 Retention = SUM(d1_retained_users) / SUM(d1_observable_users)
```