-- load_data.sql
-- Loads all 6 CSVs into retail_ops_analytics in dependency order.

USE retail_ops_analytics;

SET GLOBAL local_infile = 1;
SET FOREIGN_KEY_CHECKS = 0;

-- products
TRUNCATE TABLE products;

LOAD DATA LOCAL INFILE '/Users/hollyphan/documents/retail-ops-analytics/data/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, flavor_profile, base_price,
 is_seasonal, @season, is_crowd_favorite, is_active)
SET
  season = NULLIF(@season, '');

-- events
TRUNCATE TABLE events;

LOAD DATA LOCAL INFILE '/Users/hollyphan/documents/retail-ops-analytics/data/events.csv'
INTO TABLE events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(event_id, event_name, event_type, @event_date, neighborhood,
 @duration_hours, booth_fee, @estimated_attendance, weather_condition)
SET
  event_date           = NULLIF(@event_date, ''),
  duration_hours       = NULLIF(@duration_hours, ''),
  estimated_attendance = NULLIF(@estimated_attendance, '');

-- customers
TRUNCATE TABLE customers;

LOAD DATA LOCAL INFILE '/Users/hollyphan/documents/retail-ops-analytics/data/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, first_name, email,
 acquisition_event_id, acquisition_date, zip_code);

-- orders
TRUNCATE TABLE orders;

LOAD DATA LOCAL INFILE '/Users/hollyphan/documents/retail-ops-analytics/data/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_date, customer_id, event_id, order_channel);

-- order_items
TRUNCATE TABLE order_items;

LOAD DATA LOCAL INFILE '/Users/hollyphan/documents/retail-ops-analytics/data/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_item_id, order_id, product_id, purchase_type,
 quantity, unit_price, line_total);

-- inventory
TRUNCATE TABLE inventory;

LOAD DATA LOCAL INFILE '/Users/hollyphan/documents/retail-ops-analytics/data/inventory.csv'
INTO TABLE inventory
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(inventory_id, event_id, product_id,
 quantity_produced, quantity_sold);

SET FOREIGN_KEY_CHECKS = 1;