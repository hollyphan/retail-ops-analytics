# Product Mix Analysis

## Query 1: Purchase Format Mix and Revenue Contribution

**Business Question**
How does purchase format affect order volume, average order value, and total revenue contribution?

**What the Data Shows**

| purchase_type | total_orders | avg_order_value | total_revenue |
|---|---|---|---|
| individual | 902 | $5.00 | $4,510.00 |
| 3_pack | 704 | $12.99 | $9,144.96 |
| 6_pack | 393 | $24.00 | $9,432.00 |

Order counts split roughly 45% / 35% / 20% across individual / 3-pack / 6-pack, matching the fixed weights used to generate the data. Average order value is not a distribution with variance — it is a fixed number per purchase type ($5.00, $12.99, $24.00), because price is assigned directly by purchase format with no discounting or quantity variation. AOV here validates the pricing structure; it does not describe customer spending behavior.

**So What**
Individual purchases are the largest order segment by count but the smallest by revenue. Bundled purchases (3-pack + 6-pack) are 54.9% of orders but 80.5% of total revenue ($18,576.96 of $23,086.96). Revenue is disproportionately concentrated in bundle formats.

**Recommendation**
Increasing bundle adoption is a larger revenue lever than acquiring more individual-purchase customers. Since AOV is fixed by format rather than driven by customer choice within a format, the actionable variable is the share of orders that convert to 3-pack or 6-pack, not pricing within a format. Future work should look at what drives format selection (event type, channel, product availability) to identify where to push bundle conversion.

**Limitation**
This dataset assigns purchase format independently of any customer attribute. The analysis shows revenue mechanics of the current pricing model, not evidence of customer preference or behavior change.

---

## Query 2: Top Co-Purchased Product Pairs

**Business Question**
Which products are most frequently purchased together in the same order?

**What the Data Shows**
Top 5 product pairs by number of distinct orders containing both products (see query output for exact pairs/counts).

**So What**
These pairs represent the most common co-occurrences by raw order count. They are useful for identifying which products already tend to appear in the same basket.

**Recommendation**
Frequently co-occurring pairs are reasonable candidates for physical placement (table/signage adjacency) or preorder bundling, since they already travel together in real orders.

**Limitation**
This query measures frequency, not affinity. Because product selection during order generation is weighted toward crowd-favorite products, a pair with high frequency may simply reflect two independently popular products appearing together by base-rate chance, not a genuine pairing effect. Confirming true affinity would require a lift calculation (observed co-occurrence vs. expected co-occurrence given each product's individual popularity). Without that calculation, this result should not be used to claim one product drives sales of another, and should not be presented as a validated bundle recommendation on its own.

---

## Query 3: Online vs. In-Person Revenue Split

**Business Question**
How does revenue, order volume, and average order value differ across sales channels?

**What the Data Shows**

| order_channel | total_orders | total_revenue | avg_order_value |
|---|---|---|---|
| in_person | 1,986 | $22,898.02 | $11.53 |
| online | 13 | $188.94 | $14.53 |

Purchase type mix by channel:

| order_channel | purchase_type | total_orders |
|---|---|---|
| in_person | individual | 899 |
| in_person | 3_pack | 698 |
| in_person | 6_pack | 389 |
| online | 3_pack | 6 |
| online | 6_pack | 4 |
| online | individual | 3 |

In-person accounts for nearly all revenue and order volume, driven by event structure (dozens of cafe popups, festivals, and markets across the year vs. a single online pickup event). Online AOV ($14.53) is higher than in-person ($11.53), and the online sample shows a higher bundle share (10 of 13 orders, 77%) than in-person (54.8%).

**So What**
The volume gap is a direct, expected consequence of event structure and is not in question. The AOV gap is not reliable evidence of a channel effect. Purchase format is assigned independently of channel in the data-generating process, with fixed weights of 45% individual / 35% 3-pack / 20% 6-pack regardless of channel. At n=13 online orders, a mix of 3/6/4 is well within normal variation from those weights and does not indicate online customers behave differently.

**Recommendation**
Use channel-level analysis to understand revenue and volume scale, not basket-size behavior. No pricing or bundling decision should be based on the online AOV figure at current sample size.

**Limitation**
Online channel analysis is constrained by only 13 orders. The observed bundle concentration may reflect random variation rather than a persistent customer preference. Channel-level basket behavior should be revisited once the online order sample is large enough to distinguish a real effect from noise.