--Checking for Nulls in a seperate query--
--Identified orderID, CustomerID, ProductID, and SellerID as key columns--
--Some tables dont have every one of these key columns ,set to 0 if not in table--
--Used Round to divide Null by Total and mukltiply by 100--

SELECT
    'orders' AS tableName,
    COUNT(*) AS totalRows,
    ROUND(100.0 * SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS nullCustomerIdPercent,
    ROUND(100.0 * SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS nullOrderIdPercent,
    0 AS nullProductIdPercent,
    0 AS nullSellerIdPercent,
From orders

    UNION ALL

SELECT
    'orderItems',
    COUNT(*) AS totalRows,
    ROUND(100.0 * SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
    ROUND(100.0 * SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
    ROUND(100.0 * SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
    0 AS nullCustomerIdPercent,
FROM order_items

    UNION ALL

SELECT
    'orderPayments',
    COUNT(*) AS total_rows,
    ROUND(100.0 * SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
    0 AS nullCustomerIdPercent,
    0 AS nullProductIdPercent,
    0 AS nullSellerIdPercent,
FROM order_payments

    UNION ALL

SELECT
    'orderReviews',
    COUNT(*) AS total_rows,
    ROUND(100.0 * SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
    0 AS nullCustomerIdPercent,
    0 AS nullProductIdPercent,
    0 AS nullSellerIdPercent,
FROM order_reviews

    UNION ALL

SELECT
    'customers',
    COUNT(*) AS total_rows,
    ROUND(100.0 * SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
    0 AS nullOrderIdPercent,
    0 AS nullProductIdPercent,
    0 AS nullSellerIdPercent,
FROM customers

    UNION ALL

SELECT
    'products',
    COUNT(*) AS total_rows,
    ROUND(100.0 * SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
    0 AS nullOrderIdPercent,
    0 AS nullCustomerIdPercent,
    0 AS nullSellerIdPercent,
FROM products

    UNION ALL

SELECT
    'sellers',
    COUNT(*) AS total_rows,
    ROUND(100.0 * SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
    0 AS nullOrderIdPercent,
    0 AS nullCustomerIdPercent,
    0 AS nullProductIdPercent,
FROM sellers;
