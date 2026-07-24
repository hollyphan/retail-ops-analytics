-- Business Question:
-- Which customers are most valuable, loyal, or at risk based on purchasing behavior?
-- Approach:
-- Grain: one row per customer.
-- Recency: days since last order using a fixed analysis date (max order date + 1 day).
-- Frequency: total number of orders per customer using fixed thresholds.
-- Monetary: total customer spend from order-level totals.
-- Scoring:
--   Recency: reverse NTILE(4), most recent customers receive highest score.
--   Frequency: fixed thresholds based on observed order count distribution
--     (1 -> 265 customers, 2 -> 248, 3 -> 187, 4+ -> 152; verified via diagnostic query).
--   Monetary: NTILE(4) based on total spend
--     (range $5.00-$108.99, avg $27.10, stddev $17.92, 57 distinct values; verified via diagnostic query).
-- Final output includes RFM code and business segment labels.
-- Segment priority: Can't Lose Them is evaluated before At Risk Loyal Customers,
-- giving high monetary value priority over high frequency for inactive customers,
-- since high-value inactive customers warrant stronger win-back priority.

WITH analysis_date AS (
    SELECT
        MAX(order_date) + INTERVAL 1 DAY AS analysis_date
    FROM orders
),
order_totals AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.line_total) AS order_total
    FROM orders o
    INNER JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.customer_id,
        o.order_date
),
customer_aggregation AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date,
        COUNT(order_id) AS order_count,
        SUM(order_total) AS total_spend
    FROM order_totals
    GROUP BY customer_id
),
recency_calc AS (
    SELECT
        ca.customer_id,
        ca.last_order_date,
        ca.order_count,
        ca.total_spend,
        DATEDIFF(ad.analysis_date, ca.last_order_date) AS recency_days
    FROM customer_aggregation ca
    CROSS JOIN analysis_date ad
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        order_count,
        total_spend,
        5 - NTILE(4) OVER (
            ORDER BY recency_days ASC, customer_id ASC
        ) AS r_score,
        CASE
            WHEN order_count = 1 THEN 1
            WHEN order_count = 2 THEN 2
            WHEN order_count = 3 THEN 3
            ELSE 4
        END AS f_score,
        NTILE(4) OVER (
            ORDER BY total_spend ASC, customer_id ASC
        ) AS m_score
    FROM recency_calc
),
rfm_final AS (
    SELECT
        customer_id,
        recency_days,
        order_count,
        total_spend,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score) AS rfm_code
    FROM rfm_scores
)
SELECT
    customer_id,
    recency_days,
    order_count,
    total_spend,
    r_score,
    f_score,
    m_score,
    rfm_code,
    CASE
        WHEN r_score >= 3
             AND f_score >= 3
             AND m_score >= 3
            THEN 'Champions'

        WHEN r_score >= 3
             AND f_score >= 2
            THEN 'Loyal Customers'

        WHEN r_score >= 3
             AND f_score = 1
            THEN 'Recent Customers'

        WHEN r_score <= 2
             AND m_score >= 3
            THEN 'Can''t Lose Them'

        WHEN r_score <= 2
             AND f_score >= 3
            THEN 'At Risk Loyal Customers'

        ELSE 'Hibernating'

    END AS customer_segment
FROM rfm_final;
