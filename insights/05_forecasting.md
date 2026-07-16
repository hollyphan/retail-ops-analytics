# 05 — Demand Planning Baseline

This document covers the four analyses in `05_forecasting.sql`. This is a
demand planning baseline built from moving averages and historical
volatility, not a time-series forecast. Only one year of data (2024)
exists, so there is no repeated yearly seasonality to validate against.
Conclusions here describe what the observed year suggests, not a
predictive model.

## Query 1: Monthly Product Demand Baseline

**Business question:** What is the monthly unit demand for each product,
with seasonal products scoped only to the months they are actually
offered?

**What the data shows:** The 10 non-seasonal products each show 12
months of demand, ranging from single digits (Vietnamese Coffee, 10
units in January) to over 90 units in a strong month (Pandan Coconut,
91 units in March). The two seasonal products are scoped differently:
Bolo Bao appears only across its spring/summer window (March–August,
6 months), and Sweet Corn appears only across its fall/winter window
(January–February and September–December, 6 months). Missing months for
seasonal products are not gaps in the data; they represent months the
product was not offered.

**So what:** The dataset supports two different planning models by
design. Non-seasonal products can be evaluated on a full 12-month basis.
Seasonal products can only be evaluated within their active window, and
any comparison across the full calendar year will be misleading unless
that window is respected.

**Recommendation:** Treat non-seasonal and seasonal products as separate
planning tracks going forward. Any dashboard or report built on top of
this data should filter or label seasonal products explicitly rather
than presenting all 12 products on one undifferentiated monthly axis.

**Limitation:** Only 2 of 12 products are seasonal. This is not enough
seasonal products to generalize about seasonal demand patterns in
general; findings here are specific to Bolo Bao and Sweet Corn, not
seasonal products as a category.

---

## Query 2: Moving Average Trend & Current Production Baseline

**Business question:** What is the smoothed demand trend for each
product, and what single number should represent its current production
baseline?

**What the data shows:** A trailing 3-month moving average was
calculated for every product-month (Query 2A), then the most recent
available month was pulled out per product to serve as its current
baseline (Query 2B). For the 10 non-seasonal products, this baseline
comes from December 2024 in every case, so the moving average reflects
Oct/Nov/Dec, genuinely recent history. Bolo Bao's baseline instead comes
from August 2024 (its last in-season month), which means its moving
average reflects Jun/Jul/Aug, roughly 4 months stale relative to
December. Sweet Corn's baseline comes from December, since its season
runs into winter, so it does not have the same staleness problem.

**So what:** A single "production baseline" column is only directly
comparable across products if every product's baseline comes from the
same point in time. It does not, and that difference is not cosmetic:
Bolo Bao's baseline number describes summer demand, not the demand level
the business would see if it started selling Bolo Bao again today.
Anyone using this baseline to plan production without checking
`baseline_month` first would silently apply a summer demand number to a
decision made in winter.

**Recommendation:** Any downstream use of `three_month_moving_avg` as a
planning number must be paired with `baseline_month`, not used alone.
For Bolo Bao specifically, the baseline should be flagged as
"pre-season" rather than "current" until the product re-enters its
active window and a fresh baseline can be calculated.

**Limitation (Query 2A specifically):** The moving average window is
defined over the 3 most recent *rows* in a product's partition, not the
3 most recent *calendar months*. For non-seasonal products these are the
same thing. For Sweet Corn, which has an interrupted selling window,
the September moving average (32.00) uses the three most recent
available sales periods, January, February, and September, rather than
three consecutive calendar months. This is a direct and
correctly-implemented consequence of Query 1's
seasonal scaffolding, but it means "3-month moving average" is a slight
misnomer for seasonal products: it smooths across observed periods, not
across 3 months of calendar time.

---

## Query 3: Forecast + Volatility

**Business question:** Which products show more volatile demand, and how
should that inform confidence in their production baseline?

**What the data shows:** Volatility (`avg_abs_pct_change`, the average
absolute month-over-month percent change) was calculated for the 10
non-seasonal products and split at the portfolio median (approximately
0.405 across the 10 non-seasonal products) into "High volatility" and
"Low volatility." Five products landed on each
side. Vietnamese Fried Banana is the most volatile product in the
portfolio (0.609), while Classic Chocolate Chip is among the most stable
(0.349). Bolo Bao and Sweet Corn have no volatility classification;
their monthly sales history is too broken up by seasonal gaps for the
month-over-month comparison this metric depends on, so they are labeled
"Seasonal product - volatility not calculated" rather than left blank or
silently excluded.

**So what:** A production baseline paired with a "High volatility" flag
carries more planning risk than the same baseline paired with "Low
volatility," even if the baseline number itself is identical. Vietnamese
Fried Banana's baseline should be treated as a rough midpoint to plan
around, not a number to produce to exactly. Classic Chocolate Chip's
baseline has lower observed volatility and therefore carries less
historical demand uncertainty.

**Recommendation:** Use the High/Low volatility flag as a planning
caution signal, not a buffer signal. The volatility metric measures
demand instability, not demand direction or the cost of excess
inventory, so it does not by itself justify producing extra. High-
volatility products warrant more conservative planning: more frequent
baseline recalculation, smaller production adjustments between events,
or a selectively tested buffer only where historical sell-through
supports carrying additional inventory.

**Limitation:** The High/Low split is a relative ranking within this
10-product portfolio, not an absolute threshold tied to any operational
risk level. With only 10 data points, the median itself is sensitive to
individual products; adding or removing even one product from the
portfolio would shift where the line falls. This classification should
be re-derived, not assumed constant, if the product lineup changes.

---

## Query 4: Event-Type Planning Baseline

**Business question:** Does product demand differ meaningfully by event
type, and which event types have enough history to plan against with
confidence?

**What the data shows:** `event_count` measures events where a product
was offered (an inventory row exists), not just events with recorded
sales, and `avg_units_sold_per_event` includes zero-sale events by
construction. Across all 12 products, `cafe_popup` and `festival` event
types generally clear the 5-event threshold for "Sufficient history."
`market` events do not: every single product shows fewer than 5 market
events (1 to 4), so every product's market-event average is flagged
"Low confidence / directional only." Festival events sit closer to the
line: most non-seasonal products clear it at 7 events, but Bolo Bao (3
events) and Sweet Corn (4 events) fall short due to their shorter active
windows.

**So what:** Market events do not currently have enough history, for any
product, to plan production against with confidence. The averages shown
for market events are directionally useful (e.g., festivals consistently
show meaningfully higher per-event volume than cafe_popup for most
products, sometimes 3x or more) but should not be treated as a reliable
number to plan exact production quantities against.

**Recommendation:** Continue tracking market-event sales as they
accumulate, but do not use market-event averages as a standalone
planning input until event_count reaches 5 or more per product. For
Bolo Bao and Sweet Corn, festival-event planning numbers should also be
treated as directional only, for the same reason.

**Limitation:** The 5-event confidence threshold is a reasonable
convention, not a statistically derived cutoff. It is meant to prevent
overconfidence in small samples, not to certify that 5+ events is
sufficient for precise production planning.
