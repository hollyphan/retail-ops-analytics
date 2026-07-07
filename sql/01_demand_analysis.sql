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