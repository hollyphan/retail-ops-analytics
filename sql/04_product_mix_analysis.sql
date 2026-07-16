-- Query 1: Purchase Format Mix and Revenue Contribution
--
-- Business Question:
-- How does purchase format affect order volume, average order value, and total revenue contribution?
--
-- Approach:
-- - Roll up order_items to one row per order using SUM(line_total).
-- - Keep purchase_type at the order level since it is constant across all items in an order.
-- - Aggregate the order-level table to compare transaction volume, average order value, and revenue contribution by purchase format.

WITH order_totals AS (
    SELECT
        order_id,
        purchase_type,
        SUM(line_total) AS order_total
    FROM order_items
    GROUP BY
        order_id,
        purchase_type
)

SELECT
    purchase_type,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(order_total), 2) AS avg_order_value,
    ROUND(SUM(order_total), 2) AS total_revenue
FROM order_totals
GROUP BY purchase_type
ORDER BY total_revenue DESC;


-- Query 2: Top Co-Purchased Product Pairs
--
-- Business Question:
-- Which products are most frequently purchased together in the same order?
--
-- Approach:
-- - Self-join order_items on order_id to identify products appearing in the same order.
-- - Use product_id < product_id to keep one directional pair and remove self-pairs.
-- - Count distinct orders to measure order-level association rather than item-row frequency.
-- - Join products twice to display product names instead of IDs.
-- - Return the top 5 product pairs by number of orders containing both products.

SELECT
    pa.product_name AS product_a,
    pb.product_name AS product_b,
    COUNT(DISTINCT oi1.order_id) AS orders_with_pair
FROM order_items oi1
JOIN order_items oi2
    ON oi1.order_id = oi2.order_id
    AND oi1.product_id < oi2.product_id
JOIN products pa
    ON oi1.product_id = pa.product_id
JOIN products pb
    ON oi2.product_id = pb.product_id
GROUP BY
    oi1.product_id,
    oi2.product_id,
    pa.product_name,
    pb.product_name
ORDER BY orders_with_pair DESC
LIMIT 5;


-- Query 3: Online vs. In-Person Revenue Split
--
-- Business Question:
-- How does revenue, order volume, and average order value differ across sales channels?
--
-- Approach:
-- - Join orders to order_items since order_channel only exists on orders.
-- - Aggregate total revenue and use COUNT(DISTINCT order_id) to avoid counting item rows as orders.
-- - Calculate average order value as total revenue divided by distinct order count.

SELECT
    o.order_channel,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.line_total), 2) AS total_revenue,
    ROUND(SUM(oi.line_total) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.order_channel
ORDER BY total_revenue DESC;


-- Purchase Type Mix by Channel Check
--
-- Business Question:
-- Are purchase format distributions similar across sales channels?
--
-- Approach:
-- - Join orders to order_items to bring order_channel and purchase_type together.
-- - Count distinct orders per channel/purchase_type combination to check whether
--   channel-level AOV differences in Query 3 reflect a real mix shift or sampling noise
--   from a small channel sample.

SELECT
    o.order_channel,
    oi.purchase_type,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_channel,
    oi.purchase_type
ORDER BY
    o.order_channel,
    total_orders DESC;