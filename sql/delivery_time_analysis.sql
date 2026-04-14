WITH delivery_times AS (
    SELECT
        o.order_id,
        c.customer_state,
        s.seller_state,
        datediff('day', o.order_purchase_timestamp, o.order_delivered_customer_date)    AS actual_days,--actual delivery days
        datediff('day', o.order_purchase_timestamp, o.order_estimated_delivery_date)    AS estimated_days,--estimated delivery days
        datediff('day', o.order_delivered_customer_date, o.order_estimated_delivery_date) AS days_early_late--days early(+) or late(-)
    FROM olist.main.orders o
    JOIN olist.main.customers c ON o.customer_id = c.customer_id
    JOIN olist.main.order_items oi ON o.order_id = oi.order_id
    JOIN olist.main.sellers s ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
--adding four tables together (orders, customers, order items, and sellers)
corridor_metrics AS (
    SELECT
        seller_state,
        customer_state,
        seller_state || ' → ' || customer_state     AS corridor,
        COUNT(*)                                     AS total_deliveries,
        ROUND(AVG(actual_days), 1)                   AS avg_actual_days,
        ROUND(AVG(estimated_days), 1)                AS avg_estimated_days,
        ROUND(AVG(days_early_late), 1)               AS avg_days_early_late,
        SUM(CASE WHEN days_early_late >= 0 THEN 1 ELSE 0 END) AS on_time_count,
        SUM(CASE WHEN days_early_late < 0  THEN 1 ELSE 0 END) AS late_count
    FROM delivery_times
    GROUP BY seller_state, customer_state
),
--got a nice arrow from microsoft word; total of on time days vs late days
corridor_rates AS (
    SELECT
        corridor,
        seller_state,
        customer_state,
        total_deliveries,
        avg_actual_days,
        avg_estimated_days,
        avg_days_early_late,
        ROUND(on_time_count * 100.0 / total_deliveries, 2)  AS on_time_rate_pct,
        ROUND(late_count    * 100.0 / total_deliveries, 2)  AS late_rate_pct,
        RANK() OVER (ORDER BY avg_days_early_late DESC)      AS rank_best_corridors,
        RANK() OVER (ORDER BY avg_days_early_late ASC)       AS rank_worst_corridors
    FROM corridor_metrics
)
--on time and late days to percentages, then rank them titling those at the top "best" and those at the bottom "worst"
SELECT
    corridor,
    total_deliveries,
    avg_actual_days,
    avg_estimated_days,
    avg_days_early_late,
    on_time_rate_pct,
    late_rate_pct,
    rank_best_corridors,
    rank_worst_corridors
FROM corridor_rates
ORDER BY avg_days_early_late DESC;
--one row per corridorsorted by avg_days_early_late descending (best a the top)
