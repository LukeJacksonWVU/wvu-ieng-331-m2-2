--Investigating Date Ranges--
--Looking at Order range to find number of days an order was placed and the total number of days--
--Cast converts data type--
    SELECT
        MIN(order_purchase_timestamp) AS firstOrderDate,
        MAX(order_purchase_timestamp) AS lastOrderDate,
        COUNT(DISTINCT DATE(order_purchase_timestamp)) AS PurchaseDays,
        CAST(MAX(order_purchase_timestamp) AS DATE) - CAST(MIN(order_purchase_timestamp) AS DATE) AS calendarDays
    FROM orders;
