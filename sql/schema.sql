-- schema.sql
-- Retail Demand Forecasting & Inventory Optimization
-- Milk & Bánh Pop-Up Analytics
--
-- Run this file to create the database and all tables.
-- Safe to re-run: DROP TABLE IF EXISTS before each CREATE.
-- Execute in order — foreign key dependencies respected.

CREATE DATABASE IF NOT EXISTS retail_ops_analytics;
USE retail_ops_analytics;

-- Drop order: child tables first to avoid FK constraint errors

DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS products;

-- products
-- Cookie catalog with flavor profile and seasonal metadata.
-- All cookies priced at $5.00. 12 flavors across 3 flavor profiles.

CREATE TABLE products (
    product_id        INT          NOT NULL AUTO_INCREMENT,
    product_name      VARCHAR(100) NOT NULL,
    flavor_profile    VARCHAR(50)  NOT NULL,
    base_price        DECIMAL(6,2) NOT NULL DEFAULT 5.00,
    is_seasonal       BOOLEAN      NOT NULL DEFAULT FALSE,
    season            VARCHAR(20)  NULL,
    is_crowd_favorite BOOLEAN      NOT NULL DEFAULT FALSE,
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT uq_products_name UNIQUE (product_name),
    CONSTRAINT chk_products_flavor_profile CHECK (
        flavor_profile IN ('tea_based', 'nutty_roasted', 'sweet_nostalgic')
    ),
    CONSTRAINT chk_products_base_price CHECK (base_price > 0),
    CONSTRAINT chk_products_season CHECK (
        season IN ('spring_summer', 'fall_winter') OR season IS NULL
    ),
    CONSTRAINT chk_products_season_consistency CHECK (
        (is_seasonal = TRUE AND season IS NOT NULL) OR
        (is_seasonal = FALSE AND season IS NULL)
    )
);

-- events
-- All sales contexts: cafe pop-ups, festivals, markets,
-- and the dummy 'Online Pickup' event for online orders.
-- North Park and Convoy are the two recurring cafe locations.

CREATE TABLE events (
    event_id             INT          NOT NULL AUTO_INCREMENT,
    event_name           VARCHAR(100) NOT NULL,
    event_type           VARCHAR(50)  NOT NULL,
    event_date           DATE         NOT NULL,
    neighborhood         VARCHAR(100) NOT NULL,
    duration_hours       DECIMAL(4,1) NOT NULL,
    booth_fee            DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    estimated_attendance INT          NOT NULL,
    weather_condition    VARCHAR(50)  NOT NULL,

    CONSTRAINT pk_events PRIMARY KEY (event_id),
    CONSTRAINT chk_events_type CHECK (
        event_type IN ('cafe_popup', 'festival', 'market', 'online_pickup')
    ),
    CONSTRAINT chk_events_duration CHECK (duration_hours > 0),
    CONSTRAINT chk_events_booth_fee CHECK (booth_fee >= 0),
    CONSTRAINT chk_events_attendance CHECK (estimated_attendance > 0),
    CONSTRAINT chk_events_weather CHECK (
        weather_condition IN ('sunny', 'cloudy', 'rainy', 'hot')
    )
);

-- customers
-- Customer records with acquisition context.
-- acquisition_event_id tracks where the customer first purchased.

CREATE TABLE customers (
    customer_id          INT          NOT NULL AUTO_INCREMENT,
    first_name           VARCHAR(50)  NOT NULL,
    email                VARCHAR(100) NOT NULL,
    acquisition_event_id INT          NOT NULL,
    acquisition_date     DATE         NOT NULL,
    zip_code             VARCHAR(10)  NOT NULL,

    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT fk_customers_event FOREIGN KEY (acquisition_event_id)
        REFERENCES events (event_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- orders
-- One record per customer transaction.
-- Online orders use the dummy 'Online Pickup' event.

CREATE TABLE orders (
    order_id      INT         NOT NULL AUTO_INCREMENT,
    order_date    DATE        NOT NULL,
    customer_id   INT         NOT NULL,
    event_id      INT         NOT NULL,
    order_channel VARCHAR(20) NOT NULL,

    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT chk_orders_channel CHECK (
        order_channel IN ('in_person', 'online')
    ),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_orders_event FOREIGN KEY (event_id)
        REFERENCES events (event_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- order_items
-- One record per cookie flavor per order.
-- Packs explode into individual flavor rows.
-- unit_price reflects per-cookie price within purchase type:
--   individual : $5.00
--   3_pack     : $4.33 (13.00 / 3)
--   6_pack     : $4.00 (24.00 / 6)

CREATE TABLE order_items (
    order_item_id INT          NOT NULL AUTO_INCREMENT,
    order_id      INT          NOT NULL,
    product_id    INT          NOT NULL,
    purchase_type VARCHAR(20)  NOT NULL,
    quantity      INT          NOT NULL,
    unit_price    DECIMAL(6,2) NOT NULL,
    line_total    DECIMAL(8,2) NOT NULL,

    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),
    CONSTRAINT chk_order_items_purchase_type CHECK (
        purchase_type IN ('individual', '3_pack', '6_pack')
    ),
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_unit_price CHECK (unit_price > 0),
    CONSTRAINT chk_order_items_line_total CHECK (line_total > 0),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- inventory
-- Production vs. sales tracking per product per event.
-- quantity_wasted is derived: quantity_produced - quantity_sold
-- Online Pickup event excluded — online orders are made to order.

CREATE TABLE inventory (
    inventory_id      INT NOT NULL AUTO_INCREMENT,
    event_id          INT NOT NULL,
    product_id        INT NOT NULL,
    quantity_produced INT NOT NULL,
    quantity_sold     INT NOT NULL,

    CONSTRAINT pk_inventory PRIMARY KEY (inventory_id),
    CONSTRAINT uq_inventory_event_product UNIQUE (event_id, product_id),
    CONSTRAINT fk_inventory_event FOREIGN KEY (event_id)
        REFERENCES events (event_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_inventory_produced CHECK (quantity_produced > 0),
    CONSTRAINT chk_inventory_sold CHECK (quantity_sold >= 0),
    CONSTRAINT chk_inventory_sold_lte_produced CHECK (
        quantity_sold <= quantity_produced
    )
);