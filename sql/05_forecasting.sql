-- Query 1: Monthly Product Demand Baseline
--
-- Business Question:
-- What is the monthly unit demand for each product across the observed
-- year, with seasonal products scoped only to their in-season months?
--
-- Approach:
-- - Non-seasonal products scaffolded across all 12 observed months via
--   distinct_months (data-derived, not a hardcoded calendar).
-- - Seasonal products (Bolo Bao, Sweet Corn) scaffolded only across
--   in-season months; season match derived from MONTH(order_date)
--   (3-8 = spring_summer, else fall_winter) compared against
--   products.season.
-- - Missing sales for non-seasonal products = true zero demand.
-- - Off-season months for seasonal products do not exist as rows.
-- - Season logic derived once in seasonal_month_candidates and
--   referenced downstream, not duplicated.
WITH monthly_sales_base AS (
    SELECT
        oi.product_id,
        p.product_name,
        DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
        oi.quantity
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
),
distinct_months AS (
    SELECT DISTINCT
        DATE_FORMAT(order_date, '%Y-%m') AS sales_month
    FROM orders
),
non_seasonal_products AS (
    SELECT
        product_id,
        product_name
    FROM products
    WHERE is_seasonal = 0
),
non_seasonal_monthly AS (
    SELECT
        nsp.product_id,
        nsp.product_name,
        dm.sales_month,
        COALESCE(SUM(msb.quantity), 0) AS units_sold
    FROM non_seasonal_products nsp
    CROSS JOIN distinct_months dm
    LEFT JOIN monthly_sales_base msb
        ON nsp.product_id = msb.product_id
        AND dm.sales_month = msb.sales_month
    GROUP BY
        nsp.product_id,
        nsp.product_name,
        dm.sales_month
),
seasonal_products AS (
    SELECT
        product_id,
        product_name,
        season
    FROM products
    WHERE is_seasonal = 1
),
seasonal_month_candidates AS (
    SELECT
        sp.product_id,
        sp.product_name,
        sp.season,
        dm.sales_month,
        CASE
            WHEN CAST(SUBSTRING(dm.sales_month, 6, 2) AS SIGNED)
                BETWEEN 3 AND 8
                THEN 'spring_summer'
            ELSE 'fall_winter'
        END AS month_season
    FROM seasonal_products sp
    CROSS JOIN distinct_months dm
),
seasonal_month_scaffold AS (
    SELECT
        product_id,
        product_name,
        sales_month
    FROM seasonal_month_candidates
    WHERE month_season = season
),
seasonal_monthly AS (
    SELECT
        sms.product_id,
        sms.product_name,
        sms.sales_month,
        COALESCE(SUM(msb.quantity), 0) AS units_sold
    FROM seasonal_month_scaffold sms
    LEFT JOIN monthly_sales_base msb
        ON sms.product_id = msb.product_id
        AND sms.sales_month = msb.sales_month
    GROUP BY
        sms.product_id,
        sms.product_name,
        sms.sales_month
),
monthly_product_demand AS (
    SELECT
        product_id,
        product_name,
        sales_month,
        units_sold
    FROM non_seasonal_monthly
    UNION ALL
    SELECT
        product_id,
        product_name,
        sales_month,
        units_sold
    FROM seasonal_monthly
)
SELECT *
FROM monthly_product_demand
ORDER BY
    product_name,
    sales_month;


-- Query 2A: 3-Month Moving Average Trend
--
-- Business Question:
-- What is the underlying monthly demand trend for each product after
-- smoothing short-term fluctuations with a trailing 3-month moving average?
--
-- Approach:
-- - Reuses the full Query 1 CTE chain to keep this script self-contained.
-- - Calculates a trailing 3-month moving average using a window function.
-- - Non-seasonal products include all observed months; seasonal products
--   include only in-season months inherited from Query 1.
-- - First and second months naturally average over the available rows.
-- - Moving average is diagnostic only (no forecasting or baseline selection).
-- - Results are rounded to 2 decimal places for readability.
WITH monthly_sales_base AS (
    SELECT
        oi.product_id,
        p.product_name,
        DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
        oi.quantity
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
),
distinct_months AS (
    SELECT DISTINCT
        DATE_FORMAT(order_date, '%Y-%m') AS sales_month
    FROM orders
),
non_seasonal_products AS (
    SELECT
        product_id,
        product_name
    FROM products
    WHERE is_seasonal = 0
),
non_seasonal_monthly AS (
    SELECT
        nsp.product_id,
        nsp.product_name,
        dm.sales_month,
        COALESCE(SUM(msb.quantity), 0) AS units_sold
    FROM non_seasonal_products nsp
    CROSS JOIN distinct_months dm
    LEFT JOIN monthly_sales_base msb
        ON nsp.product_id = msb.product_id
        AND dm.sales_month = msb.sales_month
    GROUP BY
        nsp.product_id,
        nsp.product_name,
        dm.sales_month
),
seasonal_products AS (
    SELECT
        product_id,
        product_name,
        season
    FROM products
    WHERE is_seasonal = 1
),
seasonal_month_candidates AS (
    SELECT
        sp.product_id,
        sp.product_name,
        sp.season,
        dm.sales_month,
        CASE
            WHEN CAST(SUBSTRING(dm.sales_month, 6, 2) AS SIGNED)
                BETWEEN 3 AND 8
                THEN 'spring_summer'
            ELSE 'fall_winter'
        END AS month_season
    FROM seasonal_products sp
    CROSS JOIN distinct_months dm
),
seasonal_month_scaffold AS (
    SELECT
        product_id,
        product_name,
        sales_month
    FROM seasonal_month_candidates
    WHERE month_season = season
),
seasonal_monthly AS (
    SELECT
        sms.product_id,
        sms.product_name,
        sms.sales_month,
        COALESCE(SUM(msb.quantity), 0) AS units_sold
    FROM seasonal_month_scaffold sms
    LEFT JOIN monthly_sales_base msb
        ON sms.product_id = msb.product_id
        AND sms.sales_month = msb.sales_month
    GROUP BY
        sms.product_id,
        sms.product_name,
        sms.sales_month
),
monthly_product_demand AS (
    SELECT
        product_id,
        product_name,
        sales_month,
        units_sold
    FROM non_seasonal_monthly
    UNION ALL
    SELECT
        product_id,
        product_name,
        sales_month,
        units_sold
    FROM seasonal_monthly
)
SELECT
    product_id,
    product_name,
    sales_month,
    units_sold,
    ROUND(
        AVG(units_sold) OVER (
            PARTITION BY product_id
            ORDER BY sales_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS three_month_moving_avg
FROM monthly_product_demand
ORDER BY
    product_name,
    sales_month;


-- Query 2B: Current Production Baseline
--
-- Business Question:
-- What is the latest available demand baseline for each product based on
-- recent monthly sales history?
--
-- Approach:
-- - Reuses the full Query 1 CTE chain to keep this script self-contained.
-- - Calculates a trailing 3-month moving average for each product-month.
-- - Uses ROW_NUMBER() to identify the latest available month per product.
-- - Filters to rn = 1 to create the current production baseline.
-- - Exposes baseline_month explicitly to make seasonal product staleness visible.
-- - No forecasting or volatility classification is performed here.
WITH monthly_sales_base AS (
    SELECT
        oi.product_id,
        p.product_name,
        DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
        oi.quantity
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
),
distinct_months AS (
    SELECT DISTINCT
        DATE_FORMAT(order_date, '%Y-%m') AS sales_month
    FROM orders
),
non_seasonal_products AS (
    SELECT
        product_id,
        product_name
    FROM products
    WHERE is_seasonal = 0
),
non_seasonal_monthly AS (
    SELECT
        nsp.product_id,
        nsp.product_name,
        dm.sales_month,
        COALESCE(SUM(msb.quantity), 0) AS units_sold
    FROM non_seasonal_products nsp
    CROSS JOIN distinct_months dm
    LEFT JOIN monthly_sales_base msb
        ON nsp.product_id = msb.product_id
        AND dm.sales_month = msb.sales_month
    GROUP BY
        nsp.product_id,
        nsp.product_name,
        dm.sales_month
),
seasonal_products AS (
    SELECT
        product_id,
        product_name,
        season
    FROM products
    WHERE is_seasonal = 1
),
seasonal_month_candidates AS (
    SELECT
        sp.product_id,
        sp.product_name,
        sp.season,
        dm.sales_month,
        CASE
            WHEN CAST(SUBSTRING(dm.sales_month, 6, 2) AS SIGNED)
                BETWEEN 3 AND 8
                THEN 'spring_summer'
            ELSE 'fall_winter'
        END AS month_season
    FROM seasonal_products sp
    CROSS JOIN distinct_months dm
),
seasonal_month_scaffold AS (
    SELECT
        product_id,
        product_name,
        sales_month
    FROM seasonal_month_candidates
    WHERE month_season = season
),
seasonal_monthly AS (
    SELECT
        sms.product_id,
        sms.product_name,
        sms.sales_month,
        COALESCE(SUM(msb.quantity), 0) AS units_sold
    FROM seasonal_month_scaffold sms
    LEFT JOIN monthly_sales_base msb
        ON sms.product_id = msb.product_id
        AND sms.sales_month = msb.sales_month
    GROUP BY
        sms.product_id,
        sms.product_name,
        sms.sales_month
),
monthly_product_demand AS (
    SELECT
        product_id,
        product_name,
        sales_month,
        units_sold
    FROM non_seasonal_monthly
    UNION ALL
    SELECT
        product_id,
        product_name,
        sales_month,
        units_sold
    FROM seasonal_monthly
),
moving_average_baseline AS (
    SELECT
        product_id,
        product_name,
        sales_month,
        units_sold,
        ROUND(
            AVG(units_sold) OVER (
                PARTITION BY product_id
                ORDER BY sales_month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS three_month_moving_avg
    FROM monthly_product_demand
),
baseline_ranked AS (
    SELECT
        product_id,
        product_name,
        sales_month AS baseline_month,
        units_sold,
        three_month_moving_avg,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY sales_month DESC
        ) AS rn
    FROM moving_average_baseline
)
SELECT
    product_id,
    product_name,
    baseline_month,
    units_sold,
    three_month_moving_avg
FROM baseline_ranked
WHERE rn = 1
ORDER BY
    product_name;


-- Query 3: Forecast + Volatility
--
-- Business Question:
-- Which products have higher demand volatility, and how should the
-- production baseline be interpreted relative to product behavior?
--
-- Approach:
-- - Reuses the Query 2B baseline logic to generate the latest production baseline.
-- - Re-declares the volatility calculation logic from 01 Query 4.
-- - Calculates median volatility manually because MySQL does not support
--   PERCENTILE_CONT.
-- - Ranks non-seasonal products by avg_abs_pct_change, then averages the
--   5th and 6th ranked values to calculate the median.
-- - Uses LEFT JOIN so seasonal products remain in the output.
-- - Seasonal products with NULL volatility are explicitly classified as:
--   "Seasonal product - volatility not calculated".
WITH monthly_sales_base AS (
    SELECT
        oi.product_id,
        p.product_name,
        DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
        oi.quantity
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
),
distinct_months AS (
    SELECT DISTINCT
        DATE_FORMAT(order_date, '%Y-%m') AS sales_month
    FROM orders
),
non_seasonal_products AS (
    SELECT
        product_id,
        product_name
    FROM products
    WHERE is_seasonal = 0
),
non_seasonal_monthly AS (
    SELECT
        nsp.product_id,
        nsp.product_name,
        dm.sales_month,
        COALESCE(SUM(msb.quantity), 0) AS units_sold
    FROM non_seasonal_products nsp
    CROSS JOIN distinct_months dm
    LEFT JOIN monthly_sales_base msb
        ON nsp.product_id = msb.product_id
        AND dm.sales_month = msb.sales_month
    GROUP BY
        nsp.product_id,
        nsp.product_name,
        dm.sales_month
),
seasonal_products AS (
    SELECT
        product_id,
        product_name,
        season
    FROM products
    WHERE is_seasonal = 1
),
seasonal_month_candidates AS (
    SELECT
        sp.product_id,
        sp.product_name,
        sp.season,
        dm.sales_month,
        CASE
            WHEN CAST(SUBSTRING(dm.sales_month, 6, 2) AS SIGNED)
                BETWEEN 3 AND 8
                THEN 'spring_summer'
            ELSE 'fall_winter'
        END AS month_season
    FROM seasonal_products sp
    CROSS JOIN distinct_months dm
),
seasonal_month_scaffold AS (
    SELECT
        product_id,
        product_name,
        sales_month
    FROM seasonal_month_candidates
    WHERE month_season = season
),
seasonal_monthly AS (
    SELECT
        sms.product_id,
        sms.product_name,
        sms.sales_month,
        COALESCE(SUM(msb.quantity), 0) AS units_sold
    FROM seasonal_month_scaffold sms
    LEFT JOIN monthly_sales_base msb
        ON sms.product_id = msb.product_id
        AND sms.sales_month = msb.sales_month
    GROUP BY
        sms.product_id,
        sms.product_name,
        sms.sales_month
),
monthly_product_demand AS (
    SELECT
        product_id,
        product_name,
        sales_month,
        units_sold
    FROM non_seasonal_monthly

    UNION ALL

    SELECT
        product_id,
        product_name,
        sales_month,
        units_sold
    FROM seasonal_monthly
),
moving_average_baseline AS (
    SELECT
        product_id,
        product_name,
        sales_month,
        units_sold,
        ROUND(
            AVG(units_sold) OVER (
                PARTITION BY product_id
                ORDER BY sales_month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS three_month_moving_avg
    FROM monthly_product_demand
),
baseline_ranked AS (
    SELECT
        product_id,
        product_name,
        sales_month AS baseline_month,
        units_sold,
        three_month_moving_avg,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY sales_month DESC
        ) AS rn
    FROM moving_average_baseline
),
current_baseline AS (
    SELECT
        product_id,
        product_name,
        baseline_month,
        units_sold,
        three_month_moving_avg
    FROM baseline_ranked
    WHERE rn = 1
),

/* Query 4 volatility logic */
monthly_product_sales AS (
    SELECT
        oi.product_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
        SUM(oi.quantity) AS units_sold
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE p.is_seasonal = 0
    GROUP BY
        oi.product_id,
        DATE_FORMAT(o.order_date, '%Y-%m')
),
monthly_pct_change AS (
    SELECT
        product_id,
        sales_month,
        units_sold,
        LAG(units_sold) OVER (
            PARTITION BY product_id
            ORDER BY sales_month
        ) AS previous_month_units
    FROM monthly_product_sales
),
volatility_metrics AS (
    SELECT
        product_id,
        AVG(
            ABS(
                (units_sold - previous_month_units)
                / NULLIF(previous_month_units, 0)
            )
        ) AS avg_abs_pct_change
    FROM monthly_pct_change
    WHERE previous_month_units IS NOT NULL
    GROUP BY
        product_id
),
volatility_ranked AS (
    SELECT
        product_id,
        avg_abs_pct_change,
        ROW_NUMBER() OVER (
            ORDER BY avg_abs_pct_change
        ) AS volatility_rank
    FROM volatility_metrics
),
volatility_median AS (
    SELECT
        AVG(avg_abs_pct_change) AS median_volatility
    FROM volatility_ranked
    WHERE volatility_rank IN (5, 6)
)

SELECT
    cb.product_id,
    cb.product_name,
    cb.baseline_month,
    cb.units_sold,
    cb.three_month_moving_avg,
    vr.avg_abs_pct_change,
    CASE
        WHEN vr.avg_abs_pct_change IS NULL
            THEN 'Seasonal product - volatility not calculated'
        WHEN vr.avg_abs_pct_change > vm.median_volatility
            THEN 'High volatility'
        ELSE 'Low volatility'
    END AS volatility_classification
FROM current_baseline cb
LEFT JOIN volatility_ranked vr
    ON cb.product_id = vr.product_id
CROSS JOIN volatility_median vm
ORDER BY
    cb.product_name;


-- Query 4: Event-Type Planning Baseline
--
-- Business Question:
-- How does product demand performance vary by event type, and which
-- event types provide reliable planning signals?
--
-- Approach:
-- - Uses inventory as the base table to preserve all product-event
--   availability records, including zero-sale events.
-- - event_count represents events where the product was offered
--   (an inventory row exists), not only events with sales.
-- - avg_units_sold_per_event includes zero-sale events by construction.
-- - Joins inventory to events and products only.
-- - Output grain is product x event_type.
-- - Excludes online_pickup events.
-- - Flags event types with fewer than 5 events as low confidence.
--
-- Confidence:
-- - event_count < 5 -> Low confidence / directional only
-- - event_count >= 5 -> Sufficient history
SELECT
    i.product_id,
    p.product_name,
    e.event_type,
    COUNT(DISTINCT i.event_id) AS event_count,
    ROUND(
        AVG(i.quantity_sold),
        2
    ) AS avg_units_sold_per_event,
    CASE
        WHEN COUNT(DISTINCT i.event_id) < 5
            THEN 'Low confidence / directional only'
        ELSE 'Sufficient history'
    END AS confidence_flag
FROM inventory i
JOIN events e
    ON i.event_id = e.event_id
JOIN products p
    ON i.product_id = p.product_id
WHERE e.event_type <> 'online_pickup'
GROUP BY
    i.product_id,
    p.product_name,
    e.event_type
ORDER BY
    p.product_name,
    e.event_type;
