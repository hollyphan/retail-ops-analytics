-- Query 1: Event Profitability and Efficiency
-- Business Question:
-- Which events generate the best return after accounting for
-- booth fees and duration? Does raw revenue rank agree with
-- revenue-per-hour efficiency rank?
--
-- Approach:
-- - online_pickup is excluded: it has no duration_hours or
--   event_date, so revenue-per-hour and booth-fee-adjusted
--   profit are undefined for it.
-- - CTE computes revenue and net_revenue once per event so the
--   outer query can derive per-hour and rank metrics without
--   repeating the aggregation.
-- - COALESCE guards against zero-order events even though none
--   currently exist in the data (verified before writing this).
-- - NULLIF(duration_hours, 0) guards the division even though no
--   zero/NULL durations exist among non-online_pickup events
--   (also verified).
-- - RANK() is used for both rankings since they are compared by
--   position here, not subtracted; no BIGINT UNSIGNED underflow
--   risk in this query.
 
WITH event_revenue AS (
    SELECT
        e.event_id,
        e.event_name,
        e.event_type,
        e.neighborhood,
        e.event_date,
        e.duration_hours,
        e.booth_fee,
        ROUND(COALESCE(SUM(oi.line_total), 0), 2) AS revenue,
        ROUND(
            COALESCE(SUM(oi.line_total), 0) - e.booth_fee,
            2
        ) AS net_revenue
    FROM events AS e
    LEFT JOIN orders AS o
        ON e.event_id = o.event_id
    LEFT JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE e.event_type != 'online_pickup'
    GROUP BY e.event_id
)
 
SELECT
    event_id,
    event_name,
    event_type,
    neighborhood,
    event_date,
    duration_hours,
    booth_fee,
    revenue,
    net_revenue,
    ROUND(revenue / NULLIF(duration_hours, 0), 2) AS revenue_per_hour,
    ROUND(net_revenue / NULLIF(duration_hours, 0), 2) AS net_revenue_per_hour,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    RANK() OVER (
        ORDER BY net_revenue / NULLIF(duration_hours, 0) DESC
    ) AS efficiency_rank
FROM event_revenue
ORDER BY
    revenue_rank,
    efficiency_rank;
 
 
-- Supporting Check: Cafe Popup Revenue by Duration
-- Business Question: Does cafe_popup revenue scale with booked
-- duration, or does efficiency drop as duration increases?
-- Approach: Reuses the same event_revenue CTE and exclusion logic as
-- Query 1. Filtered to cafe_popup only and grouped by duration_hours,
-- since this pattern was specific to that event type -- festival and
-- market showed no comparable duration effect.

WITH event_revenue AS (
    SELECT
        e.event_id,
        e.event_type,
        e.duration_hours,
        e.booth_fee,
        ROUND(COALESCE(SUM(oi.line_total), 0), 2) AS revenue,
        ROUND(
            COALESCE(SUM(oi.line_total), 0) - e.booth_fee,
            2
        ) AS net_revenue
    FROM events AS e
    LEFT JOIN orders AS o
        ON e.event_id = o.event_id
    LEFT JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE e.event_type = 'cafe_popup'
    GROUP BY e.event_id
)

SELECT
    duration_hours,
    COUNT(*) AS event_count,
    ROUND(AVG(revenue), 2) AS avg_revenue,
    ROUND(
        AVG(net_revenue / NULLIF(duration_hours, 0)),
        2
    ) AS avg_net_revenue_per_hour
FROM event_revenue
GROUP BY duration_hours
ORDER BY duration_hours;


-- Query 2: Neighborhood Performance
-- Business Question:
-- Which neighborhoods generate the strongest overall sales, and
-- how repeatable is that performance per appearance?
--
-- Approach:
-- - Reuses the same event_revenue CTE and exclusion logic as
--   Query 1 for consistent financial definitions.
-- - Grain is neighborhood, not event, since some neighborhoods
--   (Convoy, Little Italy) host multiple event types.
-- - Includes both total and per-event averages, and both gross
--   and net revenue, since booth fees differ by event type and a
--   gross-only ranking would distort the comparison.
-- - Event-type counts are included directly in this query so the
--   event-type mix confound is visible rather than hidden. This
--   table alone cannot separate a location effect from an
--   event-type effect; see Query 3.
 
WITH event_revenue AS (
    SELECT
        e.event_id,
        e.event_type,
        e.neighborhood,
        e.booth_fee,
        ROUND(COALESCE(SUM(oi.line_total), 0), 2) AS revenue,
        ROUND(
            COALESCE(SUM(oi.line_total), 0) - e.booth_fee,
            2
        ) AS net_revenue
    FROM events AS e
    LEFT JOIN orders AS o
        ON e.event_id = o.event_id
    LEFT JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE e.event_type != 'online_pickup'
    GROUP BY e.event_id
)
 
SELECT
    neighborhood,
    COUNT(event_id) AS events,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(net_revenue), 2) AS total_net_revenue,
    ROUND(AVG(revenue), 2) AS avg_revenue_per_event,
    ROUND(AVG(net_revenue), 2) AS avg_net_revenue_per_event,
    COUNT(CASE WHEN event_type = 'festival' THEN 1 END) AS festival_events,
    COUNT(CASE WHEN event_type = 'market' THEN 1 END) AS market_events,
    COUNT(CASE WHEN event_type = 'cafe_popup' THEN 1 END) AS cafe_popup_events
FROM event_revenue
GROUP BY neighborhood
ORDER BY
    total_net_revenue DESC,
    total_revenue DESC;
 
 
-- Query 3: Neighborhood x Event Type Breakdown
-- Business Question:
-- When comparing the same event format, does one neighborhood
-- outperform another? This isolates location from event-type mix,
-- which Query 2 cannot do on its own.
--
-- Approach:
-- - Reuses the same event_revenue CTE and exclusion logic.
-- - Grain is neighborhood + event_type, so each row reflects one
--   location running one format.
-- - The cleanest comparison is within cafe_popup, where two
--   neighborhoods (Convoy, North Park) each have n=13 and the
--   same $0 booth fee structure. Other event types have thinner
--   samples (n=1 to n=3) and should be read as single-observation
--   or small-sample results, not confirmed neighborhood patterns.
 
WITH event_revenue AS (
    SELECT
        e.event_id,
        e.event_type,
        e.neighborhood,
        e.booth_fee,
        ROUND(COALESCE(SUM(oi.line_total), 0), 2) AS revenue,
        ROUND(
            COALESCE(SUM(oi.line_total), 0) - e.booth_fee,
            2
        ) AS net_revenue
    FROM events AS e
    LEFT JOIN orders AS o
        ON e.event_id = o.event_id
    LEFT JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE e.event_type != 'online_pickup'
    GROUP BY e.event_id
)
 
SELECT
    neighborhood,
    event_type,
    COUNT(event_id) AS event_count,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(net_revenue), 2) AS total_net_revenue,
    ROUND(AVG(revenue), 2) AS avg_revenue_per_event,
    ROUND(AVG(net_revenue), 2) AS avg_net_revenue_per_event
FROM event_revenue
GROUP BY
    neighborhood,
    event_type
ORDER BY
    event_type,
    avg_net_revenue_per_event DESC;
 