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
-- Segments (7 total):
--   Champions                 - strict top tier: r=4, f=4, m=4
--   Loyal High-Value Customers - r>=3, f>=3, m>=3, excluding strict Champions
--   Loyal Customers            - r>=3, f>=2, not already captured above
--   Recent Customers           - r>=3, f=1
--   Can't Lose Them            - r<=2, m>=3 (inactive but historically high value)
--   At Risk Loyal Customers    - r<=2, f>=3, m<3 (inactive, frequent, not top monetary)
--   Hibernating                - r<=2, remaining low-value inactive customers
-- Segment priority notes:
--   Champions before Loyal High-Value Customers: strict condition is a subset of the looser one.
--   Loyal High-Value Customers before Loyal Customers: f>=3 is a subset of f>=2.
--   Can't Lose Them before At Risk Loyal Customers: monetary value prioritized over frequency
--     for inactive customers, since high-value inactive customers warrant stronger win-back priority.

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
        -- Highest-value customers: top recency, top frequency, top monetary
        WHEN r_score = 4
             AND f_score = 4
             AND m_score = 4
            THEN 'Champions'

        -- High-value repeat customers: strong across all dimensions
        -- but do not meet the strict champion criteria
        WHEN r_score >= 3
             AND f_score >= 3
             AND m_score >= 3
            THEN 'Loyal High-Value Customers'

        -- Recent repeat customers who are not high-value
        WHEN r_score >= 3
             AND f_score >= 2
            THEN 'Loyal Customers'

        -- Recent one-time buyers
        WHEN r_score >= 3
             AND f_score = 1
            THEN 'Recent Customers'

        -- Inactive but historically valuable customers
        WHEN r_score <= 2
             AND m_score >= 3
            THEN 'Can''t Lose Them'

        -- Inactive frequent customers who are not top monetary
        WHEN r_score <= 2
             AND f_score >= 3
            THEN 'At Risk Loyal Customers'

        -- Remaining inactive low-value customers
        ELSE 'Hibernating'

    END AS customer_segment
FROM rfm_final;
