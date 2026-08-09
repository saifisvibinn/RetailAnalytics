-- =============================================================================
-- Table: workspace.gold.fact_payments
-- Grain: One row per payment line
-- Primary Key: (order_id, payment_sequential)
-- =============================================================================

CREATE OR REPLACE TABLE workspace.gold.fact_payments AS
SELECT
    p.order_id,
    p.payment_sequential,
    o.customer_id,
    o.order_status,
    INITCAP(REPLACE(p.payment_type, '_', ' ')) AS payment_type,
    p.payment_installments,
    p.payment_value,
    o.order_purchase_timestamp,
    CAST(o.order_purchase_timestamp AS DATE) AS order_purchase_date,
    c.customer_state
FROM workspace.silver.order_payments p
JOIN workspace.silver.orders o
    ON p.order_id = o.order_id
JOIN workspace.silver.customers c
    ON o.customer_id = c.customer_id;

-- Delta Lake Physical Layout Optimization
OPTIMIZE workspace.gold.fact_payments
ZORDER BY (order_purchase_date, payment_type);

-- Column statistics for Spark Cost-Based Optimizer
ANALYZE TABLE workspace.gold.fact_payments COMPUTE STATISTICS FOR ALL COLUMNS;
