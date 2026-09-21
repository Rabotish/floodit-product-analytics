ASSERT (
    EXISTS (
        SELECT 1
        FROM `firebase-public-project.analytics_153293282.events_20180612`
        LIMIT 1
    )
)
AS 'First raw Firebase table is unavailable or empty';


ASSERT (
    EXISTS (
        SELECT 1
        FROM `firebase-public-project.analytics_153293282.events_20181003`
        LIMIT 1
    )
)
AS 'Last raw Firebase table is unavailable or empty';
