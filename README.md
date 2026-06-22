# Retail Demand Forecasting & Inventory Optimization

## Overview

This project builds a demand forecasting and inventory optimization
system for a pop-up retail operation — identifying which products,
events, and customer segments drive profitability, and generating
production recommendations to minimize waste and maximize revenue
per event.

The analysis covers 18 months of simulated sales, inventory, and
event performance data across six normalized tables, producing
actionable recommendations a business operator could act on
immediately.

---

## Business Problem

Small pop-up retail businesses operate with limited capital and no
margin for waste. Every event requires production decisions made days
in advance with imperfect information:

- How much of each product should be produced?
- Which events are actually worth attending after accounting for costs?
- Which products drive the most revenue per event?
- Which combinations of products increase average order value?

Poor answers to these questions result in wasted inventory, missed
revenue, and unprofitable events. This project builds the analytical
foundation to answer them systematically.

---

## Dataset

**Source:** Synthetic data generated to reflect realistic small
business pop-up operations. Distributions, pricing, event types,
and seasonal patterns are informed by real operational experience
running a San Diego-based pop-up business.

**Scale:**
- ~40–60 events across 18 months
- ~1,500–2,500 orders
- ~4,000–7,000 order line items
- 6 normalized tables

**Tables:**

| Table | Description | Rows (approx) |
|---|---|---|
| `products` | Product catalog with pricing and categories | ~15 |
| `customers` | Customer records with acquisition context | ~800–1,200 |
| `events` | Pop-up events with cost and operational data | ~50 |
| `orders` | One record per customer transaction | ~2,000 |
| `order_items` | One record per product per order | ~5,500 |
| `inventory` | Production vs. sales by product by event | ~500 |

---

## Data Model

*ERD diagram to be added.*

**Key relationships:**
- One event contains many orders
- One order contains many order items
- Each order item references one product
- Inventory tracks production and sales per product per event
- Customers are acquired at a specific event

---

## SQL Techniques Demonstrated

| Technique | Where Used |
|---|---|
| Multi-table JOINs | All analysis files |
| CTEs | Forecasting, cohort logic |
| Window functions (LAG, RANK, rolling avg) | Demand trends, event ranking |
| CASE WHEN | Segmentation, waste classification |
| Subqueries | Product mix analysis |
| Aggregations and GROUP BY | Revenue and inventory summaries |
| Date functions | Seasonality, month-over-month analysis |
| Derived metrics | Waste rate, revenue per hour, profitability |

---

## Analysis Sections

**01 — Demand Analysis**
Which products drive revenue? Which have seasonal patterns?

**02 — Inventory Optimization**
Where is waste occurring? What production levels maximize sell-through?

**03 — Event Performance**
Which events generate the best return after accounting for booth fees
and duration?

**04 — Product Mix**
Which products are bought together? Which combinations increase
average order value?

**05 — Forecasting**
Simple moving average demand forecasts and production recommendations
for upcoming events.

---

## How to Run

1. Run `sql/schema.sql` to create the database and all tables
2. Run the Python data generation script to populate `data/`
3. Load CSVs using `sql/load_data.sql`
4. Execute analysis files in numbered order

**Requirements:** MySQL 9.7+, Python 3.x, TablePlus (optional GUI)

---

## Tools

- MySQL 9.7
- Python (synthetic data generation)
- TablePlus
- Tableau