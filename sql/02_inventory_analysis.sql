-- Business Question: How does inventory performance vary across products?
-- Approach: Calculate sell-through rate, leftover units, and sold-through event
-- frequency per product. Sold-through events are structurally near-impossible
-- given the data generator's production buffer logic (min buffer of 5 units),
-- so sold_through_events/pct are expected to be 0 across the board. Crowd
-- favorites (is_crowd_favorite = 1) show meaningfully higher sell-through than
-- non-favorites, which validates the dataset's demand model rather than
-- surfacing a new business insight.

SELECT
    p.product_name,
    COUNT(*) AS events_offered,
    SUM(i.quantity_produced) AS total_produced,
    SUM(i.quantity_sold) AS total_sold,
    SUM(i.quantity_produced - i.quantity_sold) AS leftover_units,
    ROUND(
        SUM(i.quantity_sold) * 100.0
        / SUM(i.quantity_produced),
        2
    ) AS overall_sell_through_pct,
    SUM(
        CASE
            WHEN i.quantity_sold = i.quantity_produced THEN 1
            ELSE 0
        END
    ) AS sold_through_events,
    ROUND(
        SUM(
            CASE
                WHEN i.quantity_sold = i.quantity_produced THEN 1
                ELSE 0
            END
        ) * 100.0
        / COUNT(*),
        2
    ) AS sold_through_event_pct
FROM inventory AS i
JOIN products AS p
    ON i.product_id = p.product_id
WHERE i.quantity_produced > 0
GROUP BY p.product_id, p.product_name
ORDER BY overall_sell_through_pct DESC,
         sold_through_event_pct DESC;

-- Business Question: How do different event types affect inventory efficiency?
-- Approach: Join inventory to events and compare total produced, total sold,
-- leftover units, and sell-through % by event type, using inventory rows
-- (one product per event) as the unit of analysis. Sell-through % is
-- SUM(sold)/SUM(produced), not an average of per-row rates, to weight larger
-- production runs appropriately. Leftover units reflect production scale more
-- than efficiency; sell-through % is the actual efficiency metric.

SELECT
    e.event_type,
    COUNT(*) AS inventory_records,
    SUM(i.quantity_produced) AS total_produced,
    SUM(i.quantity_sold) AS total_sold,
    SUM(i.quantity_produced - i.quantity_sold) AS total_leftover_units,
    ROUND(
        SUM(i.quantity_sold) * 100.0
        / SUM(i.quantity_produced),
        2
    ) AS overall_sell_through_pct,
    ROUND(
        AVG(i.quantity_produced - i.quantity_sold),
        2
    ) AS avg_leftover_per_product
FROM inventory AS i
JOIN events AS e
    ON i.event_id = e.event_id
WHERE i.quantity_produced > 0
GROUP BY e.event_type
ORDER BY overall_sell_through_pct DESC,
         avg_leftover_per_product ASC;

-- Supporting Check: Does estimated attendance explain the demand and
-- efficiency differences seen across event types in Query 2?
-- Approach: Aggregate inventory to the event grain first (CTE), then join to
-- events and compare average estimated attendance, average units sold per
-- product (event-weighted average, not volume-weighted), and overall
-- sell-through % by event type. Attendance tracks demand intensity
-- monotonically, but does not fully explain sell-through efficiency —
-- market events break the expected ordering, with n=4 limiting confidence
-- in that result.

WITH event_sales AS (
    SELECT
        event_id,
        SUM(quantity_sold) AS total_event_sales,
        SUM(quantity_produced) AS total_event_produced,
        COUNT(*) AS products_offered
    FROM inventory
    GROUP BY event_id
)
SELECT
    e.event_type,
    COUNT(*) AS events,
    ROUND(AVG(e.estimated_attendance), 0) AS avg_estimated_attendance,
    ROUND(AVG(es.total_event_sales / es.products_offered), 2) AS avg_units_sold_per_product,
    ROUND(
        SUM(es.total_event_sales) * 100.0 /
        SUM(es.total_event_produced),
        2
    ) AS overall_sell_through_pct
FROM events e
JOIN event_sales es
    ON e.event_id = es.event_id
GROUP BY e.event_type
ORDER BY avg_estimated_attendance DESC;-- Supporting Check: Produced-to-Sold Ratio by Event Type
-- Business Question: Is market overproduced relative to sales by a
-- larger margin than other event types, and could that help explain
-- its lower sell-through rate observed in Query 2?
-- Approach: AVG(quantity_produced) / AVG(quantity_sold) is used as the
-- primary ratio rather than dividing MIN/MAX by an average, since an
-- extremum divided by an average produces a number with no clear
-- interpretation. MIN/MAX are retained as separate descriptive columns
-- showing production spread within each event type, not folded into
-- the ratio itself. This uses only persisted quantity_produced/sold
-- values -- it does not attempt to reconstruct the data generator's
-- internal production-floor random draw, which is not recoverable from
-- persisted data (see generate_data.py: qty_produced = max(qty_sold +
-- buffer, random.randint(lo, hi)) -- only the max survives).

SELECT
    e.event_type,
    ROUND(AVG(i.quantity_produced), 2) AS avg_quantity_produced,
    ROUND(AVG(i.quantity_sold), 2) AS avg_units_sold_per_product,
    ROUND(AVG(i.quantity_produced) / AVG(i.quantity_sold), 2) AS produced_to_sold_ratio,
    MIN(i.quantity_produced) AS min_quantity_produced,
    MAX(i.quantity_produced) AS max_quantity_produced
FROM inventory AS i
JOIN events AS e
    ON i.event_id = e.event_id
WHERE e.event_type != 'online_pickup'
GROUP BY e.event_type
ORDER BY produced_to_sold_ratio DESC;
