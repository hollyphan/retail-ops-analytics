-- Business Question:
-- Which products drive the most revenue and sales volume, including products with no sales activity?

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

-- Business Question:
-- Which products show meaningful disagreement between their volume rank and revenue rank? 
-- Products with high volume but low revenue rank may be underpriced or over-indexed in low-margin bundles. Products with highrevenue but low volume rank may be premium items with pricing power.
-- Uses DENSE_RANK() so tied products don't introduce artificial gaps that would distort the rank_gap calculation.

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
    volume_rank - revenue_rank AS rank_gap
FROM ranked_products
WHERE volume_rank <> revenue_rank
ORDER BY ABS(volume_rank - revenue_rank) DESC;

-- Business Question:
-- Do products designated as seasonal actually perform better during their assigned season? Compare each seasonal product's in-season and off-season sales volume and revenue to identify products whose demand aligns (or does not align) with their expected season.
-- The order season is derived once from order_date and mapped to the same season labels used in the products table. Conditional aggregation then produces one row per product with separate in-season and off-season metrics.

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