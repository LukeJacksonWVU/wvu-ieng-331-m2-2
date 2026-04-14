--Looking into days missing, this gets the start and end date--
--Setting the date bounds by using the max and min order date from the orders table--
    WITH dateBounds AS (
            SELECT
            CAST(MIN(order_purchase_timestamp) AS DATE) AS startDate,
            CAST(MAX(order_purchase_timestamp) AS DATE) AS endDate
            FROM orders),
--Generate_series function built into duckDB with an interval of 1 day with start and end from previous section--
--List every calander day (Youtube video showed me how to do this)--
        calendar AS (
            SELECT CAST(generate_series AS DATE) AS calanderDate
            FROM generate_series(
            (SELECT startDate FROM dateBounds),
            (SELECT endDate   FROM dateBounds),
            INTERVAL '1 day')),
--Counts where orders were placed and stores it as DailyOrders--
        dailyOrders AS (
            SELECT
            CAST(order_purchase_timestamp AS DATE) AS orderDate,
            COUNT(*) AS orders
            FROM orders
            GROUP BY CAST(order_purchase_timestamp AS DATE)),
--Assigns number to gap days in order where there is no value. This is a way to group the gaps--
--Subtracts the date by the number, you end up with an arbitrary date but it is the same date--
--This creates a group--
--This is where AI helped the most and something I couldnt figure out on my own--
--Explained much better in the README after farther research--
        gapGroups AS (
            SELECT
            c.calanderDate,
            c.calanderDate - CAST(ROW_NUMBER() OVER (ORDER BY c.calanderDate) AS INTEGER) AS gapGroup
            FROM calendar AS c
            LEFT JOIN dailyOrders AS d ON c.calanderDate = d.orderDate
            WHERE d.orderDate IS NULL)

--Getting the beginning and end of the gap from the GAPGROUP, counting everything as the missing days--
--Using a case when to catagorise the gaps--
--Ordering by the gap start date--

        SELECT
            MIN(calanderDate) AS gapStart,
            MAX(calanderDate) AS gapEnd,
            COUNT(*) AS missingDays,
            CASE
                WHEN COUNT(*) = 1  THEN 'single day'
                WHEN COUNT(*) <= 3 THEN 'short gap (≤ 3 days)'
                WHEN COUNT(*) <= 7 THEN 'week-level gap'
                ELSE '!!!Extended gap!!! (> 7 days)'
            END AS Severity
        FROM gapGroups
        GROUP BY gapGroup
        ORDER BY gapStart;
