-- Parameters:
--   $1 :: DATE  -- start_date filter (NULL = no lower bound, applied to first order)
--   $2 :: DATE  -- end_date filter   (NULL = no upper bound, applied to first order)

WITH resolved_customers AS (
    SELECT
        o.order_id,
        o.order_purchase_timestamp,
        c.customer_zip_code_prefix || '_' || c.customer_city AS customer_unique
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND ($1::DATE IS NULL OR o.order_purchase_timestamp::DATE >= $1::DATE)
      AND ($2::DATE IS NULL OR o.order_purchase_timestamp::DATE <= $2::DATE)
),
first_orders AS (
    SELECT
        customer_unique,
        order_id                                                    AS first_order_id,
        order_purchase_timestamp                                    AS first_order_ts,
        CAST(DATE_TRUNC('month', order_purchase_timestamp) AS DATE) AS cohort_month
    FROM (
        SELECT
            customer_unique, order_id, order_purchase_timestamp,
            ROW_NUMBER() OVER (
                PARTITION BY customer_unique
                ORDER BY order_purchase_timestamp ASC, order_id ASC
            ) AS rn
        FROM resolved_customers
    ) ranked
    WHERE rn = 1
      AND ($1 IS NULL OR CAST(order_purchase_timestamp AS DATE) >= $1)
      AND ($2 IS NULL OR CAST(order_purchase_timestamp AS DATE) <= $2)
),
subsequent_orders AS (
    SELECT
        rc.customer_unique,
        MIN(rc.order_purchase_timestamp) AS second_order_ts
    FROM resolved_customers rc
    JOIN first_orders fo
        ON  rc.customer_unique = fo.customer_unique
        AND rc.order_id        != fo.first_order_id
    GROUP BY rc.customer_unique
),
cohort_activity AS (
    SELECT
        fo.cohort_month,
        fo.customer_unique,
        datediff('day', fo.first_order_ts, so.second_order_ts) AS days_to_return,
        CASE WHEN so.second_order_ts IS NOT NULL
              AND datediff('day', fo.first_order_ts, so.second_order_ts) <= 30
             THEN 1 ELSE 0 END AS retained_30d,
        CASE WHEN so.second_order_ts IS NOT NULL
              AND datediff('day', fo.first_order_ts, so.second_order_ts) <= 60
             THEN 1 ELSE 0 END AS retained_60d,
        CASE WHEN so.second_order_ts IS NOT NULL
              AND datediff('day', fo.first_order_ts, so.second_order_ts) <= 90
             THEN 1 ELSE 0 END AS retained_90d
    FROM first_orders fo
    LEFT JOIN subsequent_orders so ON fo.customer_unique = so.customer_unique
)
SELECT
    cohort_month,
    COUNT(*)                                        AS cohort_size,
    SUM(retained_30d)                               AS returned_30d,
    ROUND(SUM(retained_30d) * 100.0 / COUNT(*), 2) AS retention_rate_30d,
    SUM(retained_60d)                               AS returned_60d,
    ROUND(SUM(retained_60d) * 100.0 / COUNT(*), 2) AS retention_rate_60d,
    SUM(retained_90d)                               AS returned_90d,
    ROUND(SUM(retained_90d) * 100.0 / COUNT(*), 2) AS retention_rate_90d
FROM cohort_activity
GROUP BY cohort_month
ORDER BY cohort_month ASC;
