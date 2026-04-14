--Removing Duplicates--
--Doing it with products, orders, and customers--

WITH
    duplicateOrders AS (
        SELECT order_id, COUNT(*) AS cnt
        FROM orders
        GROUP BY order_id
        HAVING COUNT(*) > 1),

    duplicateCustomers AS (
        SELECT customer_unique_id, COUNT(*) AS cnt
        FROM customers
        GROUP BY customer_unique_id
        HAVING COUNT(*) > 1),

    duplicateProducts AS (
        SELECT product_id, COUNT(*) AS cnt
        FROM products
        GROUP BY product_id
        HAVING COUNT(*) > 1)
SELECT
    'orders' AS tableName,
    COUNT(*) AS duplicateKeys,
    COALESCE(SUM(cnt), 0) AS totalDuplicateRows
FROM duplicateOrders

UNION ALL

SELECT
    'customers',
    COUNT(*),
    COALESCE(SUM(cnt), 0)
FROM duplicateCustomers

UNION ALL

SELECT
    'products',
    COUNT(*),
    COALESCE(SUM(cnt), 0)
FROM duplicateProducts;
