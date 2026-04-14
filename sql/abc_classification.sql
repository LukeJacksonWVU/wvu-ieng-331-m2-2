-- Parameters:
--   $1 :: DATE     -- start_date filter (NULL = no lower bound)
--   $2 :: DATE     -- end_date filter   (NULL = no upper bound)

WITH product_revenue AS (
    SELECT
        oi.product_id,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
      AND ($1 IS NULL OR CAST(o.order_purchase_timestamp AS DATE) >= $1)
      AND ($2 IS NULL OR CAST(o.order_purchase_timestamp AS DATE) <= $2)
    GROUP BY oi.product_id
),
revenue_with_totals AS (
    SELECT
        product_id,
        total_revenue,
        SUM(total_revenue) OVER ()                                   AS grand_total,
        ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 4) AS revenue_pct,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC)        AS running_total
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
SELECT
    c.product_id,
    ct.product_category_name_english AS category,
    c.total_revenue,
    c.revenue_pct,
    c.cumulative_pct,
    c.abc_tier
FROM classified c
LEFT JOIN products p             ON c.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
ORDER BY c.total_revenue DESC;
