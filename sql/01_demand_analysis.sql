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