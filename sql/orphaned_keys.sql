--Orphaned Keys, Looking at 4 key columns identified above--
--Seeing if orders refrence customers that dont exist by refrencing both tables customer Ids and counting where null--

SELECT 'orphanedCustomerId' As foreignKeys,
    COUNT(*) AS orphan_count
    FROM orders AS o
    LEFT JOIN customers AS c
        ON o.customer_id = c.customer_id
    WHERE c.customer_id IS NULL

UNION ALL

SELECT 'orphanedOrderId',
    COUNT(*) AS orphan_count
    FROM order_items AS oi
    LEFT JOIN orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_id IS NULL

UNION ALL

SELECT 'orphanedProductId',
    COUNT(*) AS orphan_count
    FROM order_items AS oi
    LEFT JOIN products AS p
        ON oi.product_id = p.product_id
    WHERE p.product_id IS NULL

UNION ALL

SELECT 'orphanedSellerId',
    COUNT(*) AS orphan_count
    FROM order_items AS oi
    LEFT JOIN sellers AS s
        ON oi.seller_id = s.seller_id
    WHERE s.seller_id IS NULL;
