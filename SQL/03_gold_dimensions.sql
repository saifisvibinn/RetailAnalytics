-- =============================================================================
-- Dimension Tables (workspace.gold)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. dim_customer (One row per unique human customer)
-- Primary Key: customer_unique_id
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.gold.dim_customer AS
SELECT DISTINCT
    customer_unique_id,
    FIRST(customer_city) AS customer_city,
    FIRST(customer_state) AS customer_state
FROM workspace.silver.customers
GROUP BY customer_unique_id;

-- -----------------------------------------------------------------------------
-- 2. dim_product (One row per product)
-- Primary Key: product_id
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.gold.dim_product AS
SELECT DISTINCT
    product_id,
    INITCAP(REPLACE(product_category_name_english, '_', ' ')) AS product_category,
    product_category_name AS product_category_portuguese,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM workspace.silver.products;

-- -----------------------------------------------------------------------------
-- 3. dim_sellers (One row per seller)
-- Primary Key: seller_id
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.gold.dim_sellers AS
SELECT DISTINCT
    seller_id,
    INITCAP(seller_city) AS seller_city,
    seller_state
FROM workspace.silver.sellers;

-- -----------------------------------------------------------------------------
-- 4. dim_order_status (One row per order status)
-- Primary Key: order_status
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.gold.dim_order_status AS
SELECT DISTINCT order_status
FROM workspace.gold.fact_orders
WHERE order_status IS NOT NULL
ORDER BY order_status;

-- -----------------------------------------------------------------------------
-- 5. dim_date (Generated calendar dimension: 2016-01-01 to 2018-12-31)
-- Primary Key: date_key
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.gold.dim_date AS
SELECT 
    datum AS date_key,
    YEAR(datum) AS year,
    MONTH(datum) AS month_number,
    DATE_FORMAT(datum, 'MMMM') AS month_name,
    QUARTER(datum) AS quarter,
    DATE_FORMAT(datum, 'EEEE') AS day_of_week,
    DAYOFWEEK(datum) AS day_number,
    CASE WHEN DAYOFWEEK(datum) IN (1, 7) THEN true ELSE false END AS is_weekend
FROM (
    SELECT EXPLODE(SEQUENCE(DATE'2016-01-01', DATE'2018-12-31', INTERVAL 1 DAY)) AS datum
);

-- ANALYZE STATISTICS FOR ALL DIMENSIONS
ANALYZE TABLE workspace.gold.dim_customer COMPUTE STATISTICS FOR ALL COLUMNS;
ANALYZE TABLE workspace.gold.dim_product COMPUTE STATISTICS FOR ALL COLUMNS;
ANALYZE TABLE workspace.gold.dim_sellers COMPUTE STATISTICS FOR ALL COLUMNS;
ANALYZE TABLE workspace.gold.dim_date COMPUTE STATISTICS FOR ALL COLUMNS;
ANALYZE TABLE workspace.gold.dim_order_status COMPUTE STATISTICS FOR ALL COLUMNS;
