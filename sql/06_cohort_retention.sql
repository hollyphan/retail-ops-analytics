/*
Business Question:
How well does the business retain customers after acquisition, and how does retention change over time across acquisition cohorts?

Approach:
1. Assign each customer to an acquisition cohort using customers.acquisition_date.
2. Calculate a fixed cohort size for each acquisition month.
3. Identify each customer's purchasing activity by month after acquisition.
4. Aggregate active customers by cohort and month offset.
5. Generate the full range of observable month offsets independently of activity data.
6. Build a scaffold to preserve the cohort retention triangle, including months with zero retained customers.
7. Calculate monthly retention rates for each acquisition cohort.
*/
WITH RECURSIVE customer_cohorts AS (
    SELECT
        customer_id,
        DATE_FORMAT(acquisition_date, '%Y-%m-01') AS cohort_month
    FROM customers
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
customer_activity AS (
    SELECT
        cc.customer_id,
        cc.cohort_month,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS activity_month,
        TIMESTAMPDIFF(
            MONTH,
            cc.cohort_month,
            DATE_FORMAT(o.order_date, '%Y-%m-01')
        ) AS month_number
    FROM customer_cohorts cc
    JOIN orders o
        ON cc.customer_id = o.customer_id
),
customer_activity_agg AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) AS retained_customers
    FROM customer_activity
    GROUP BY
        cohort_month,
        month_number
),
month_number_range AS (
    SELECT 0 AS month_number

    UNION ALL

    SELECT month_number + 1
    FROM month_number_range
    WHERE month_number < (
        SELECT TIMESTAMPDIFF(
            MONTH,
            MIN(cohort_month),
            (
                SELECT DATE_FORMAT(MAX(order_date), '%Y-%m-01')
                FROM orders
            )
        )
        FROM cohort_sizes
    )
),
cohort_month_range AS (
    SELECT
        cs.cohort_month,
        mnr.month_number
    FROM cohort_sizes cs
    CROSS JOIN month_number_range mnr
    WHERE mnr.month_number <= TIMESTAMPDIFF(
        MONTH,
        cs.cohort_month,
        (
            SELECT DATE_FORMAT(MAX(order_date), '%Y-%m-01')
            FROM orders
        )
    )
)
SELECT
    cmr.cohort_month,
    cmr.month_number,
    COALESCE(caa.retained_customers, 0) AS retained_customers,
    cs.cohort_size,
    ROUND(
        COALESCE(caa.retained_customers, 0) / cs.cohort_size * 100,
        2
    ) AS retention_rate
FROM cohort_month_range cmr
LEFT JOIN customer_activity_agg caa
    ON cmr.cohort_month = caa.cohort_month
   AND cmr.month_number = caa.month_number
JOIN cohort_sizes cs
    ON cmr.cohort_month = cs.cohort_month
ORDER BY
    cmr.cohort_month,
    cmr.month_number;
