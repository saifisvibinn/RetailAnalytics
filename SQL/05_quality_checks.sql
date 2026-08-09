-- =============================================================================
-- Automated Data Quality Assurance Suite
-- Layer: Quality Checks (Post-Gold execution)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TEST 1: PRIMARY KEY UNIQUENESS
-- -----------------------------------------------------------------------------
SELECT 
    'fact_orders' AS table_name,
    'order_id + order_item_id' AS pk,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) AS distinct_keys,
    CASE WHEN COUNT(*) = COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) 
         THEN '✅ PASS' ELSE '❌ FAIL: DUPLICATES' END AS result
FROM workspace.gold.fact_orders

UNION ALL

SELECT 
    'fact_payments',
    'order_id + payment_sequential',
    COUNT(*),
    COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential)),
    CASE WHEN COUNT(*) = COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential)) 
         THEN '✅ PASS' ELSE '❌ FAIL: DUPLICATES' END
FROM workspace.gold.fact_payments

UNION ALL

SELECT 
    'dim_customer',
    'customer_unique_id',
    COUNT(*),
    COUNT(DISTINCT customer_unique_id),
    CASE WHEN COUNT(*) = COUNT(DISTINCT customer_unique_id) 
         THEN '✅ PASS' ELSE '❌ FAIL: DUPLICATES' END
FROM workspace.gold.dim_customer

UNION ALL

SELECT 
    'dim_product',
    'product_id',
    COUNT(*),
    COUNT(DISTINCT product_id),
    CASE WHEN COUNT(*) = COUNT(DISTINCT product_id) 
         THEN '✅ PASS' ELSE '❌ FAIL: DUPLICATES' END
FROM workspace.gold.dim_product

UNION ALL

SELECT 
    'dim_sellers',
    'seller_id',
    COUNT(*),
    COUNT(DISTINCT seller_id),
    CASE WHEN COUNT(*) = COUNT(DISTINCT seller_id) 
         THEN '✅ PASS' ELSE '❌ FAIL: DUPLICATES' END
FROM workspace.gold.dim_sellers

UNION ALL

SELECT 
    'dim_date',
    'date_key',
    COUNT(*),
    COUNT(DISTINCT date_key),
    CASE WHEN COUNT(*) = COUNT(DISTINCT date_key) 
         THEN '✅ PASS' ELSE '❌ FAIL: DUPLICATES' END
FROM workspace.gold.dim_date

UNION ALL

SELECT 
    'dim_order_status',
    'order_status',
    COUNT(*),
    COUNT(DISTINCT order_status),
    CASE WHEN COUNT(*) = COUNT(DISTINCT order_status) 
         THEN '✅ PASS' ELSE '❌ FAIL: DUPLICATES' END
FROM workspace.gold.dim_order_status;

-- -----------------------------------------------------------------------------
-- TEST 2: NULL CHECKS ON CRITICAL COLUMNS
-- -----------------------------------------------------------------------------
SELECT 
    'fact_orders.order_id' AS check_column,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_count,
    COUNT(*) AS total_rows,
    ROUND(SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS null_pct,
    CASE WHEN SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END AS result
FROM workspace.gold.fact_orders

UNION ALL

SELECT 'fact_orders.customer_unique_id',
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END),
    COUNT(*),
    ROUND(SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),
    CASE WHEN SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END
FROM workspace.gold.fact_orders

UNION ALL

SELECT 'fact_orders.order_status',
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END),
    COUNT(*),
    ROUND(SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),
    CASE WHEN SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END
FROM workspace.gold.fact_orders

UNION ALL

SELECT 'fact_orders.price',
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END),
    COUNT(*),
    ROUND(SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),
    CASE WHEN SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) < COUNT(*) * 0.05 
         THEN '✅ PASS (< 5%)' ELSE '❌ FAIL (> 5%)' END
FROM workspace.gold.fact_orders

UNION ALL

SELECT 'fact_payments.payment_value',
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END),
    COUNT(*),
    ROUND(SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),
    CASE WHEN SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) = 0 
         THEN '✅ PASS' ELSE '❌ FAIL' END
FROM workspace.gold.fact_payments;

-- -----------------------------------------------------------------------------
-- TEST 3: REFERENTIAL INTEGRITY (FOREIGN KEYS)
-- -----------------------------------------------------------------------------
SELECT 
    'fact_orders → dim_customer' AS relationship,
    COUNT(*) AS orphan_rows,
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL: ORPHANS' END AS result
FROM workspace.gold.fact_orders f
WHERE f.customer_unique_id IS NOT NULL
AND f.customer_unique_id NOT IN (SELECT customer_unique_id FROM workspace.gold.dim_customer)

UNION ALL

SELECT 
    'fact_orders → dim_product',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL: ORPHANS' END
FROM workspace.gold.fact_orders f
WHERE f.product_id IS NOT NULL
AND f.product_id NOT IN (SELECT product_id FROM workspace.gold.dim_product)

UNION ALL

SELECT 
    'fact_orders → dim_sellers',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL: ORPHANS' END
FROM workspace.gold.fact_orders f
WHERE f.seller_id IS NOT NULL
AND f.seller_id NOT IN (SELECT seller_id FROM workspace.gold.dim_sellers)

UNION ALL

SELECT 
    'fact_orders → dim_order_status',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL: ORPHANS' END
FROM workspace.gold.fact_orders f
WHERE f.order_status NOT IN (SELECT order_status FROM workspace.gold.dim_order_status)

UNION ALL

SELECT 
    'fact_payments → dim_order_status',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL: ORPHANS' END
FROM workspace.gold.fact_payments f
WHERE f.order_status NOT IN (SELECT order_status FROM workspace.gold.dim_order_status);

-- -----------------------------------------------------------------------------
-- TEST 4: VALUE RANGE CHECKS
-- -----------------------------------------------------------------------------
SELECT 
    'Negative prices' AS check_name,
    COUNT(*) AS count,
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END AS result
FROM workspace.gold.fact_orders
WHERE price < 0

UNION ALL

SELECT 'Negative freight',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM workspace.gold.fact_orders
WHERE freight_value < 0

UNION ALL

SELECT 'Negative payment_value',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM workspace.gold.fact_payments
WHERE payment_value < 0

UNION ALL

SELECT 'Future order dates',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN '✅ PASS' ELSE '❌ FAIL' END
FROM workspace.gold.fact_orders
WHERE order_purchase_date > CURRENT_DATE();

-- -----------------------------------------------------------------------------
-- TEST 5: CROSS-LAYER REVENUE RECONCILIATION
-- -----------------------------------------------------------------------------
SELECT
    silver_price,
    gold_price,
    ROUND(ABS(silver_price - gold_price), 2) AS price_difference,
    CASE WHEN ABS(silver_price - gold_price) < 1 
         THEN '✅ PASS' ELSE '❌ FAIL: REVENUE MISMATCH' END AS revenue_check,
    silver_payments,
    gold_payments,
    ROUND(ABS(silver_payments - gold_payments), 2) AS payment_difference,
    CASE WHEN ABS(silver_payments - gold_payments) < 1 
         THEN '✅ PASS' ELSE '❌ FAIL: PAYMENT MISMATCH' END AS payment_check
FROM (
    SELECT 
        (SELECT ROUND(SUM(price), 2) FROM workspace.silver.order_items) AS silver_price,
        (SELECT ROUND(SUM(price), 2) FROM workspace.gold.fact_orders) AS gold_price,
        (SELECT ROUND(SUM(payment_value), 2) FROM workspace.silver.order_payments) AS silver_payments,
        (SELECT ROUND(SUM(payment_value), 2) FROM workspace.gold.fact_payments) AS gold_payments
);
