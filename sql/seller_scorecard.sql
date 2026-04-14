WITH seller_revenue AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id)                AS total_orders,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
    FROM olist.main.order_items oi
    JOIN olist.main.orders o ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY oi.seller_id
),
--seller ids in items; sum price and freight to get total cost and group by seller (cancellations ignored)
seller_delivery AS (
    SELECT
        oi.seller_id,
        ROUND(
            SUM(
                CASE
                    WHEN CAST(o.order_delivered_customer_date AS DATE)
                         <= CAST(o.order_estimated_delivery_date AS DATE)
                    THEN 1 ELSE 0
                END
                --if it was delivered on time (1) if it was not (0)
            ) * 100.0 / COUNT(DISTINCT o.order_id),
        2) AS on_time_rate_pct
        --converts to  rate of on time
    FROM olist.main.order_items oi
    JOIN olist.main.orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY oi.seller_id
),
--gets rid of null
seller_reviews AS (
    SELECT
        oi_dedup.seller_id,
        ROUND(AVG(r.review_score), 2) AS avg_review_score
    FROM (
        SELECT DISTINCT seller_id, order_id
        FROM olist.main.order_items
    ) oi_dedup
    JOIN olist.main.order_reviews r ON oi_dedup.order_id = r.order_id
    GROUP BY oi_dedup.seller_id
),
--order can have multiple items from the same seller, gets rid of that, so seller is accounted for once
seller_cancellations AS (
    SELECT
        oi.seller_id,
        ROUND(
            SUM(
                CASE
                    WHEN o.order_status IN ('canceled', 'unavailable')
                    THEN 1 ELSE 0
                END
            ) * 100.0 / COUNT(DISTINCT o.order_id),
        2) AS cancellation_rate_pct
    FROM olist.main.order_items oi
    JOIN olist.main.orders o ON oi.order_id = o.order_id
    GROUP BY oi.seller_id
),
--same idea as previous section
combined_metrics AS (
    SELECT
        s.seller_id,
        s.seller_city,
        s.seller_state,
        COALESCE(sr.total_orders,          0) AS total_orders,
        COALESCE(sr.total_revenue,         0) AS total_revenue,
        COALESCE(sd.on_time_rate_pct,      0) AS on_time_rate,
        COALESCE(sv.avg_review_score,      0) AS avg_review_score,
        COALESCE(sc.cancellation_rate_pct, 0) AS cancellation_rate
    FROM olist.main.sellers s
    LEFT JOIN seller_revenue       sr ON s.seller_id = sr.seller_id
    LEFT JOIN seller_delivery      sd ON s.seller_id = sd.seller_id
    LEFT JOIN seller_reviews       sv ON s.seller_id = sv.seller_id
    LEFT JOIN seller_cancellations sc ON s.seller_id = sc.seller_id
),
--rates the seller--had to do a little googling for this bc it caused a little block, but the solution was left joins--essentially attaches the metrics to the sellers table
normalized AS (
    SELECT
        seller_id,
        seller_city,
        seller_state,
        total_orders,
        total_revenue,
        on_time_rate,
        avg_review_score,
        cancellation_rate,

        (total_revenue - MIN(total_revenue) OVER ())
            / (MAX(total_revenue) OVER () - MIN(total_revenue) OVER ())
                                                AS norm_revenue,

        (on_time_rate - MIN(on_time_rate) OVER ())
            / (MAX(on_time_rate) OVER () - MIN(on_time_rate) OVER ())
                                                AS norm_on_time,

        (avg_review_score - MIN(avg_review_score) OVER ())
            / (MAX(avg_review_score) OVER () - MIN(avg_review_score) OVER ())
                                                AS norm_review,

        1 - (cancellation_rate - MIN(cancellation_rate) OVER ())
            / (MAX(cancellation_rate) OVER () - MIN(cancellation_rate) OVER ())
                                                AS norm_cancellation
    FROM combined_metrics
)
 --same formula for the four metrics-uses these to assign score, cancellation rate is diff so a 0 cancellation rate is received as good
 SELECT
     seller_id,
     seller_city,
     seller_state,
     total_orders,
     total_revenue,
     on_time_rate        AS on_time_rate_pct,
     avg_review_score,
     cancellation_rate   AS cancellation_rate_pct,

     ROUND(
         (norm_revenue      * 0.30) +
         (norm_on_time      * 0.30) +
         (norm_review       * 0.25) +
         (norm_cancellation * 0.15),
     4) AS composite_score,
  --the composite score
     DENSE_RANK() OVER (
         ORDER BY
             (norm_revenue      * 0.30) +
             (norm_on_time      * 0.30) +
             (norm_review       * 0.25) +
             (norm_cancellation * 0.15)
         DESC
     ) AS seller_rank
  --rank them by comp score
 FROM normalized
 ORDER BY seller_rank ASC;
 --rounds the scores,
