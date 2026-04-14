WITH product_revenue AS (
    SELECT
        oi.product_id,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
    FROM olist.main.order_items oi
    JOIN olist.main.orders o ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY oi.product_id
),
--similar to seller_performance (total cost for product)
revenue_with_totals AS (
    SELECT
        product_id,
        total_revenue,
        SUM(total_revenue) OVER ()                                  AS grand_total,--revenue for all products
        ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 4) AS revenue_pct,--how much this product contributes to total revenue
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC)       AS running_total --running total of revenue for products in descending order
    FROM product_revenue
),

classified AS (
    SELECT
        product_id,
        total_revenue,
        revenue_pct,
        ROUND(running_total * 100.0 / grand_total, 4) AS cumulative_pct,
        CASE
            WHEN running_total * 100.0 / grand_total <= 80 THEN 'A'
            WHEN running_total * 100.0 / grand_total <= 95 THEN 'B'
            ELSE 'C'
        END AS abc_tier
    FROM revenue_with_totals
)
--cumulative percentages with A, B, C tiers for top 80, next 15, and next 5
SELECT
    c.product_id,
    ct.product_category_name_english AS category,
    c.total_revenue,
    c.revenue_pct,
    c.cumulative_pct,
    c.abc_tier
FROM classified c
LEFT JOIN olist.main.products p ON c.product_id = p.product_id
LEFT JOIN olist.main.category_translation ct ON p.product_category_name = ct.product_category_name
ORDER BY c.total_revenue DESC;
--join products and cat for readability and A tier products are first
