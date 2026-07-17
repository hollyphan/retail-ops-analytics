# Demand Analysis Insights

Analysis of Milk & Bánh sales data across 12 products, based on `sql/01_demand_analysis.sql`.

## Query 1: Revenue/Volume Leaderboard

**Business question:** Which products drive the most revenue and sales volume, including products with no sales activity?

**What the data shows:** All 12 products recorded sales. Pandan Coconut leads on both units sold (847) and revenue ($3,647.61), followed by Honey Sesame and Strawberry Milk Tea. The two seasonal products, Sweet Corn ($863.39) and Bolo Bao ($845.73), sit at the bottom of the leaderboard, but that's expected given they only sell in a single season while the other 10 products sell year-round.

**So what:** The LEFT JOIN + COALESCE design was intended to surface dead inventory (zero-sale products), but no such products exist in this dataset. That finding didn't materialize. The 10 non-seasonal products range from $1,457.89 (Classic Chocolate Chip) to $3,647.61 (Pandan Coconut) in revenue, with no single product overwhelmingly dominating or lagging.

**Recommendation:** No inventory cleanup action is warranted based on this dataset. The LEFT JOIN + COALESCE design remains valuable because it would surface discontinued or unsold products in a production environment, even though no such cases appear in this synthetic sample.

---

## Query 2: Volume Rank vs. Revenue Rank Disagreement

**Business question:** Which products show meaningful disagreement between their volume rank and revenue rank, and does that disagreement indicate a pricing or product mix issue?

**What the data shows:** 5 of 12 products show a rank gap: Matcha White Chocolate (-2), and Vietnamese Fried Banana, Vietnamese Coffee, Sweet Corn, and Bolo Bao (-1 each). All gaps are negative, meaning these products rank slightly better on volume than on revenue. A follow-up check on average revenue per unit across all 12 products found a range of $4.27 to $4.33, a 6-cent spread. Matcha White Chocolate and Honey Sesame are effectively tied for the lowest per-unit revenue ($4.2743 vs. $4.2747, a $0.0004 gap — rounding noise, not a real difference), but only Matcha White Chocolate shows a rank gap. If per-unit price were driving the gap, Honey Sesame should show one too.

**So what:** The initial hypothesis, that rank gaps signal underpricing or promotional bundling, is not supported by the data. Average revenue per unit is effectively uniform across the catalog. The rank gaps are better explained by close revenue totals swapping order at the margins, not by any underlying pricing or product mix effect.

**Recommendation:** No pricing or promotional intervention is supported by this analysis. Rankings should always be interpreted alongside the underlying values, since products with nearly identical revenue can swap positions without representing a meaningful business difference. Rank-based comparisons should be paired with a magnitude check (like per-unit revenue) before being used to justify a business decision.

---

## Query 3: Seasonal Demand Pattern Analysis

**Business question:** Do products designated as seasonal actually perform better during their assigned season?

**What the data shows:** Both seasonal products show strong in-season concentration. Sweet Corn sold 199 units in-season versus 2 off-season (a 99.5x ratio); Bolo Bao sold 195 in-season versus 1 off-season (a 195x ratio). Revenue moved in the same direction: Sweet Corn's in-season revenue was $855.06 versus $8.33 off-season; Bolo Bao's was $841.40 versus $4.33.

**So what:** The seasonal designation matches actual sales behavior for both products in this dataset. However, this is based on only 2 products, so the finding is directional, not statistically robust. A pattern confirmed on n=2 doesn't generalize to a claim about "seasonal products" as a category.

**Recommendation:** The results are consistent with the current seasonal classifications for these two specific products, not proof of a broader mechanism. As more seasonal products are added to the catalog, re-run this query to confirm the pattern holds at a larger sample size before relying on it for inventory or production planning.

---

## Query 4: Non-Seasonal Month-over-Month Demand Volatility

**Business question:** Which active, non-seasonal products show meaningful month-over-month demand variation that might warrant investigation?

**What the data shows:** Vietnamese Fried Banana is the most volatile product by average absolute percent change (0.6088), followed by Honey Sesame (0.4546) and Black Sesame Dark Chocolate (0.4392). Matcha White Chocolate is the most stable (0.2904). Reactivation months (a product going from zero sales to positive sales) came back at 0 across all 10 products.

**So what:** Products with greater month-to-month demand swings are inherently harder to forecast accurately, which increases inventory planning risk. The volatility ranking identifies which products carry that risk. The reactivation metric was implemented correctly but wasn't exercised in this dataset because every active product recorded sales in every month.

**Recommendation:** Vietnamese Fried Banana, Honey Sesame, and Black Sesame Dark Chocolate show the highest volatility relative to the rest of the catalog and represent reasonable candidates for closer monitoring. There is no predefined business threshold separating these from the remaining products, so this is a relative comparison, not a fixed cutoff. The reactivation logic needs a dataset with an actual product dropout and recovery to be tested properly, which this one doesn't have.

---

## Cross-Query Notes

- Query 1's zero-sale detection and Query 4's reactivation detection are both correct designs that happened to find nothing in this particular dataset. Neither is evidence the logic is unnecessary, just that this synthetic data doesn't exercise those edge cases.
- Query 3's finding (n=2) and Query 2's disproven hypothesis are both examples of stating what the evidence actually supports rather than the more interesting story the raw numbers might suggest at first glance.
