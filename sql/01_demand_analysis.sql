-- Query 1: Revenue/Volume Leaderboard
-- Business Question:
-- Which products drive the most revenue and sales volume,
-- including products with no sales activity?
--
-- Approach:
-- - Uses LEFT JOIN + COALESCE instead of INNER JOIN so that
--   dead-inventory products (zero sales) surface in the results
--   instead of silently disappearing.

SELECT
    p.product_id,
    p.product_name,
    COALESCE(SUM(oi.quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue
FROM products AS p
LEFT JOIN order_items AS oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_name
ORDER BY
    total_revenue DESC;


-- Query 2: Volume Rank vs. Revenue Rank Disagreement
-- Business Question:
-- Which products show meaningful disagreement between their
-- volume rank and revenue rank? Products with high volume but
-- low revenue rank may be underpriced or over-indexed in
-- low-margin bundles. Products with high revenue but low volume
-- rank may be premium items with pricing power.
--
-- Approach:
-- - Uses DENSE_RANK() instead of RANK() because ranks feed into
--   arithmetic (rank_gap subtraction) — RANK()'s skipped numbers
--   after ties would distort the gap.
-- - Both DENSE_RANK() calls order DESC so rank 1 = best in both
--   metrics, keeping rank_gap's sign interpretable (negative =
--   high volume/low revenue, positive = high revenue/low volume).
-- - Casts ranks to SIGNED before subtraction because MySQL returns
--   DENSE_RANK() as an unsigned integer. Without casting, negative
--   rank gaps can trigger unsigned arithmetic errors.

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        COALESCE(SUM(oi.quantity), 0) AS units_sold,
        COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS revenue
    FROM products AS p
    LEFT JOIN order_items AS oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.product_id,
        p.product_name
),

ranked_products AS (
    SELECT
        product_id,
        product_name,
        units_sold,
        revenue,
        DENSE_RANK() OVER (
            ORDER BY units_sold DESC
        ) AS volume_rank,
        DENSE_RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM product_metrics
)

SELECT
    product_name,
    units_sold,
    revenue,
    volume_rank,
    revenue_rank,
    CAST(volume_rank AS SIGNED) - CAST(revenue_rank AS SIGNED) AS rank_gap
FROM ranked_products
WHERE volume_rank <> revenue_rank
ORDER BY ABS(
    CAST(volume_rank AS SIGNED) - CAST(revenue_rank AS SIGNED)
) DESC;


-- Query 3: Seasonal Demand Pattern Analysis
-- Business Question:
-- Do products designated as seasonal actually perform better
-- during their assigned season? Compare each seasonal product's
-- in-season and off-season sales volume and revenue to identify
-- products whose demand aligns (or does not align) with their
-- expected season.
--
-- Approach:
-- - Order season is derived once from order_date and mapped to
--   the same season labels used in the products table
--   (spring_summer, fall_winter), avoiding repeated CASE logic.
-- - Conditional aggregation produces one row per product with
--   separate in-season and off-season metrics (wide format),
--   rather than one row per product per season (tall format).
-- - Filtered to is_seasonal = 1 AND season IS NOT NULL; verified
--   via DESCRIBE that these two columns align with no mismatches
--   across all 12 products.

WITH sales_with_season AS (
    SELECT
        p.product_id,
        p.product_name,
        p.season,
        p.is_seasonal,
        oi.quantity,
        oi.unit_price,
        CASE
            WHEN MONTH(o.order_date) BETWEEN 3 AND 8 THEN 'spring_summer'
            ELSE 'fall_winter'
        END AS order_season
    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id
    INNER JOIN products AS p
        ON oi.product_id = p.product_id
),

seasonal_product_performance AS (
    SELECT
        product_id,
        product_name,
        season,

        SUM(
            CASE
                WHEN order_season = season THEN quantity
                ELSE 0
            END
        ) AS in_season_units,

        SUM(
            CASE
                WHEN order_season <> season THEN quantity
                ELSE 0
            END
        ) AS off_season_units,

        SUM(
            CASE
                WHEN order_season = season THEN quantity * unit_price
                ELSE 0
            END
        ) AS in_season_revenue,

        SUM(
            CASE
                WHEN order_season <> season THEN quantity * unit_price
                ELSE 0
            END
        ) AS off_season_revenue

    FROM sales_with_season

    WHERE
        is_seasonal = 1
        AND season IS NOT NULL

    GROUP BY
        product_id,
        product_name,
        season
)

SELECT
    product_name,
    season AS assigned_season,
    in_season_units,
    off_season_units,
    in_season_revenue,
    off_season_revenue,
    in_season_units - off_season_units AS unit_difference,
    ROUND(
        in_season_units / NULLIF(off_season_units, 0),
        2
    ) AS unit_ratio,
    in_season_revenue - off_season_revenue AS revenue_difference,
    ROUND(
        in_season_revenue / NULLIF(off_season_revenue, 0),
        2
    ) AS revenue_ratio

FROM seasonal_product_performance

ORDER BY
    ABS(revenue_difference) DESC;


-- Query 4: Non-Seasonal Month-over-Month Demand Volatility
-- Business Question:
-- Which active, non-seasonal products exhibit meaningful
-- month-over-month demand variation that may warrant
-- investigation (e.g. inventory planning, merchandising review)?
--
-- Approach:
-- - Filtered to active products (is_active = 1); discontinued
--   products reflect lifecycle behavior, not ongoing demand.
-- - Builds a complete product-month scaffold (CROSS JOIN months
--   derived from the data x non-seasonal products) so months with
--   zero sales are explicitly represented before LAG() runs,
--   ensuring consecutive-month comparisons are always valid.
-- - Uses average absolute month-over-month percentage change as
--   the primary volatility metric, since it normalizes across
--   products with different sales volumes (a flat metric would
--   flatter high-volume products and penalize low-volume ones).
-- - Zero-to-positive transitions (reactivation) are excluded from
--   percentage change, since percentage change is undefined when
--   the previous month is zero; tracked separately as a count.
-- - Positive-to-zero transitions (dropout) are valid -100% changes
--   and are NOT excluded — no special handling needed.
-- - LAG() is computed once (lagged_months) and referenced by name
--   downstream (monthly_changes) rather than recalculated.

WITH distinct_months AS (
    SELECT DISTINCT
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month
    FROM orders AS o
),

non_seasonal_products AS (
    SELECT
        p.product_id,
        p.product_name,
        p.flavor_profile
    FROM products AS p
    WHERE
        p.is_seasonal = 0
        AND p.is_active = 1
),

product_month_scaffold AS (
    SELECT
        nsp.product_id,
        nsp.product_name,
        nsp.flavor_profile,
        dm.order_month
    FROM non_seasonal_products AS nsp
    CROSS JOIN distinct_months AS dm
),

monthly_sales AS (
    SELECT
        oi.product_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        SUM(oi.quantity) AS monthly_units_sold
    FROM orders AS o
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    GROUP BY
        oi.product_id,
        DATE_FORMAT(o.order_date, '%Y-%m')
),

filled_months AS (
    SELECT
        pms.product_id,
        pms.product_name,
        pms.flavor_profile,
        pms.order_month,
        COALESCE(ms.monthly_units_sold, 0) AS monthly_units_sold
    FROM product_month_scaffold AS pms
    LEFT JOIN monthly_sales AS ms
        ON pms.product_id = ms.product_id
       AND pms.order_month = ms.order_month
),

lagged_months AS (
    SELECT
        fm.product_id,
        fm.product_name,
        fm.flavor_profile,
        fm.order_month,
        fm.monthly_units_sold,
        LAG(fm.monthly_units_sold) OVER (
            PARTITION BY fm.product_id
            ORDER BY fm.order_month
        ) AS previous_month_units
    FROM filled_months AS fm
),

monthly_changes AS (
    SELECT
        lm.product_id,
        lm.product_name,
        lm.flavor_profile,
        lm.order_month,
        lm.monthly_units_sold,
        lm.previous_month_units,

        CASE
            WHEN lm.previous_month_units = 0
             AND lm.monthly_units_sold > 0
            THEN 1
            ELSE 0
        END AS reactivation_flag

    FROM lagged_months AS lm
),

product_volatility AS (
    SELECT
        mc.product_id,
        mc.product_name,
        mc.flavor_profile,

        AVG(mc.monthly_units_sold) AS avg_monthly_units,

        AVG(
            CASE
                WHEN mc.previous_month_units > 0 THEN
                    ABS(
                        (mc.monthly_units_sold - mc.previous_month_units)
                        / mc.previous_month_units
                    )
            END
        ) AS avg_abs_pct_change,

        AVG(
            CASE
                WHEN mc.previous_month_units IS NOT NULL THEN
                    ABS(
                        mc.monthly_units_sold - mc.previous_month_units
                    )
            END
        ) AS avg_abs_unit_change,

        SUM(mc.reactivation_flag) AS reactivation_months

    FROM monthly_changes AS mc
    GROUP BY
        mc.product_id,
        mc.product_name,
        mc.flavor_profile
)

SELECT
    pv.product_id,
    pv.product_name,
    pv.flavor_profile,
    ROUND(pv.avg_monthly_units, 2) AS avg_monthly_units,
    ROUND(pv.avg_abs_pct_change, 4) AS avg_abs_pct_change,
    ROUND(pv.avg_abs_unit_change, 2) AS avg_abs_unit_change,
    pv.reactivation_months,

    DENSE_RANK() OVER (
        ORDER BY pv.avg_abs_pct_change DESC
    ) AS volatility_rank

FROM product_volatility AS pv
ORDER BY
    volatility_rank,
    pv.product_name;