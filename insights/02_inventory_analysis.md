# Inventory Analysis Insights

Analysis of Milk & Bánh inventory performance across 12 products and 407 inventory records, based on `sql/02_inventory_analysis.sql`.

## Query 1: Product-Level Sell-Through and Leftover

**Business question:** Which products sell through most efficiently, and where is excess inventory concentrated?

**What the data shows:** Sell-through rates split into two clear tiers. Pandan Coconut (49.62%), Honey Sesame (48.01%), and Strawberry Milk Tea (46.37%) lead the catalog — these are exactly the three products flagged `is_crowd_favorite = 1`. Every other product clusters between 20.94% and 26.63%, roughly half the favorites' rate. Sweet Corn and Bolo Bao, the two seasonal products, sit mid-pack at 26.63% and 24.16% despite far fewer events offered (17 and 20, versus 37 for the year-round products). Leftover units are highest for the low sell-through products, topping out at 1,287 (Hojicha White Chocolate) and 1,280 (Matcha White Chocolate) against roughly 1,600–1,700 units produced each. Sold-through events (produced = sold exactly) are 0 across all 407 records, for every product.

The zero sold-through rate is not a business finding — it's structural. The synthetic data generator sets `quantity_produced = max(quantity_sold + buffer, floor)`, where buffer is randomly 5–20 units. Production can never equal sales by construction, so this metric is guaranteed to read 0 regardless of real demand.

**So what:** The crowd-favorite flag correlating with roughly double the sell-through rate of every other product confirms the dataset behaves as intended — the demand model correctly gives favorites higher relative demand. It validates the synthetic data rather than surfacing a new business insight. Separately, the two seasonal products performing competitively despite a fraction of the events offered suggests concentrated in-season demand, consistent with what Query 3 of the demand analysis file already established.

**Recommendation:** No inventory action follows from this query in isolation — it's a data validation check, not a supply-demand finding. Sold-through events as a metric is not usable on this dataset; any real-world equivalent would need production data where sell-through can actually reach 100%.

## Query 2: Sell-Through Efficiency by Event Type

**Business question:** Do some event types produce more inventory waste than others, and is leftover volume a reliable signal of that?

**What the data shows:** Festival has the highest sell-through rate (32.91%) but also the highest average leftover per product (59.16 units). Cafe popup has the lowest average leftover (22.00 units) but the lowest sell-through rate (28.77%). Market sits in between on both measures (27.33% sell-through, 33.30 leftover). Leftover volume and sell-through efficiency move in opposite directions across event types.

**So what:** Leftover volume alone is a misleading efficiency signal. Festival isn't wasteful because it carries more surplus stock — it's producing and selling at a larger scale than the other two event types (6,789 units produced across 77 records, versus 8,835 across 286 for cafe popup and 2,016 across 44 for market), and its sell-through rate is actually the best of the three. Sell-through percentage, not raw leftover count, is the metric that reflects true efficiency.

**Recommendation:** Rank event types by sell-through % for inventory planning purposes, not leftover units. Festival is currently the most efficient event type despite carrying the most absolute surplus. Any conversation about which event type "wastes the most product" needs to be reframed around efficiency rate, not volume, or it will misdirect attention toward festival when cafe popup is actually the least efficient.

## Query 3: Attendance as an Explanation for Event-Type Differences

**Business question:** Does event attendance explain the sell-through differences observed across event types in Query 2?

**What the data shows:** Attendance and units sold per product move together cleanly: festival averages 864 attendees and 29.01 units sold per product, market averages 308 attendees and 12.52 units sold per product, and cafe popup averages 86 attendees and 8.89 units sold per product. Sell-through % does not follow the same order — festival leads at 32.91%, but cafe popup (28.77%) outperforms market (27.33%) despite cafe popup's far lower attendance.

Attendance tracks demand intensity monotonically — a clean, well-evidenced association between attendance and units sold per product, though association, not causation, since the data doesn't isolate attendance from other factors that vary by event type.

Attendance does not fully explain sell-through efficiency. Market breaks the expected ordering: mid-range attendance but the lowest sell-through rate of the three event types. Market has only 4 events in this dataset, versus 26 for cafe popup and 7 for festival — this is a low-confidence result given the sample size, not a reliable business signal.

A production-floor mismatch was tested as a possible explanation for market's anomaly — whether market events are over-produced relative to demand by a larger margin than other event types. Comparing floor-to-actual-sales ratios, market runs roughly 2.4–4.8x its 12.52 average units sold, while festival runs roughly 2.1–4.1x its 29.01 average units sold. The ratios are similar. Production floor mismatch does not clearly explain market's underperformance.

**So what:** Attendance is a real and usable predictor of demand volume — the relationship is clean enough to act on. It is not a complete explanation of efficiency differences between event types. Something else drives market's underperformance, and this dataset doesn't identify what. The most honest conclusion is that this is inconclusive, most likely due to market's small sample size (n=4), not evidence of a specific secondary cause. There is no basis in the data to name a mechanism beyond that.

**Recommendation:** Use attendance as an input to demand forecasting for Project 1's remaining files — the association is strong enough to build on. Do not draw conclusions about market events specifically until more market-event data exists. Flag market as an open question for the forecasting file, not a settled finding.
