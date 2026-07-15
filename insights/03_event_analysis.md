# Event Performance Analysis

## Query 1: Event Profitability and Efficiency

**Business Question**
Which events generate the best return after accounting for booth fees and duration? Does raw revenue rank agree with revenue-per-hour efficiency rank?

**What the Data Shows**
Festivals occupy the top 7 of 37 events on both revenue and net-revenue-per-hour, with ranks staying close together (max gap of 4, event 28). Booth fees compress festival and market returns roughly proportionally across the board, so no single event is being unfairly penalized by its fee.

The real divergence is inside cafe_popup. Bucketing cafe_popup events by duration:

| Duration | Events | Avg Revenue | Avg Revenue/Hour |
|---|---|---|---|
| 3.0 hrs | 10 | $431.67 | $143.89 |
| 4.0 hrs | 6 | $413.89 | $103.47 |
| 4.5 hrs | 10 | $410.67 | $91.26 |

Average total revenue is flat across duration, within noise at n=10 per bucket. Average revenue per hour drops 37% from the 3.0-hour bucket to the 4.5-hour bucket. Every 3.0-hour cafe_popup event ranks better on efficiency than on raw revenue; every 4.5-hour cafe_popup event ranks worse. The split is 10/10 with no exceptions on either side.

**So What**
Cafe_popup revenue does not scale with time open. Foot traffic appears bounded by something other than duration (location, time of day, existing customer base), so hours booked past roughly the 3-hour mark are not converting to additional sales. The extra 1.5 hours in the 4.5-hour slots functions as close to unpaid time. This pattern is specific to cafe_popup; festival and market events show no comparable duration effect and their efficiency ranks track revenue ranks closely.

**Recommendation**
Test shorter cafe_popup bookings (around 3 hours) as the default, and check whether the existing 4.5-hour slots share a common low-traffic time window before assuming duration itself is the sole cause. If a scheduling factor explains the pattern, fix the schedule; if not, shortening cafe_popup duration should free up time without a proportional revenue loss.

## Query 2: Neighborhood Performance

**Business Question**
Which neighborhoods perform best? Is neighborhood a real driver of performance, or is it confounded by which event types happen to be hosted where?

**What the Data Shows**
Ranked by total net revenue, Convoy leads ($8,930.07) followed by North Park ($6,354.08), Little Italy ($3,120.81), Kearny Mesa ($1,366.62), Barrio Logan ($1,122.57), and Mission Hills ($623.87). But Convoy's lead is a volume effect: 16 events versus North Park's 15, both dominated by cafe_popup (13 events each). On avg_net_revenue_per_event alone, Convoy ($558.13) actually looks stronger than North Park ($423.61), which suggested a location effect worth checking. Little Italy, Kearny Mesa, and Barrio Logan all show higher per-event averages, but at n=3, n=1, and n=1 respectively, none of those are stable enough to support a neighborhood claim.

Breaking the comparison out by neighborhood and event_type isolates the confound. Within cafe_popup specifically, the only format with a matched sample at both locations:

| Neighborhood | Events | Avg Net Revenue/Event |
|---|---|---|
| Convoy | 13 | $421.79 |
| North Park | 13 | $417.19 |

A $4.60 gap across 13 events each is noise. Convoy's higher blended average in the neighborhood-only table came entirely from its 3 extra festival events, not from Convoy outperforming North Park at the same event format. Festival events net roughly 2.5 to 3 times what cafe_popup events net regardless of neighborhood (Convoy festivals average $1,148.92/event, Little Italy $1,278.01/event, both well above either neighborhood's cafe_popup average).

**So What**
Once event format is held constant, Convoy and North Park are statistically indistinguishable as locations. The apparent neighborhood ranking in the initial query was an artifact of event-type mix, not evidence that one location is a better market than the other. Event format, not neighborhood, is the stronger driver of per-event net revenue in this dataset. Kearny Mesa, Barrio Logan, Little Italy, and Mission Hills all have samples too thin (n=1 to n=3) to support any location-quality conclusion; they are single-event observations, not neighborhood patterns.

**Recommendation**
Prioritize booking more festival- and market-format events over cafe_popup, since format drives net revenue per appearance far more than neighborhood choice does. Do not use total net revenue by neighborhood as a location-quality signal without controlling for event-type mix first. Before treating Little Italy, Kearny Mesa, or Barrio Logan as promising locations, more events need to run there to build a sample large enough to trust.
