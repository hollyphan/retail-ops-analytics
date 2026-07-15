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