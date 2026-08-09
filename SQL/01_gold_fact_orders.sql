-- =============================================================================
-- Table: workspace.gold.fact_orders
-- Grain: One row per order item
-- Primary Key: (order_id, order_item_id)
-- =============================================================================

CREATE OR REPLACE TABLE workspace.gold.fact_orders AS
SELECT 
    o.order_id,
    COALESCE(i.order_item_id, 0) AS order_item_id,
    o.customer_id,
    c.customer_unique_id,
    o.order_status,
    o.order_purchase_timestamp,
    CAST(o.order_purchase_timestamp AS DATE) AS order_purchase_date,
    o.order_approved_at,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_city,
    c.customer_state,
    i.product_id,
    i.seller_id,
    INITCAP(REPLACE(p.product_category_name_english, '_', ' ')) AS product_category,
    i.price,
    i.freight_value,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_days,
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN true 
        ELSE false 
    END AS is_late_delivery
FROM workspace.silver.orders o
JOIN workspace.silver.customers c 
    ON o.customer_id = c.customer_id
LEFT JOIN workspace.silver.order_items i 
    ON o.order_id = i.order_id
LEFT JOIN workspace.silver.products p 
    ON i.product_id = p.product_id;

-- Delta Lake Physical Layout Optimization
OPTIMIZE workspace.gold.fact_orders
ZORDER BY (order_purchase_date, customer_state);

-- Column statistics for Spark Cost-Based Optimizer
ANALYZE TABLE workspace.gold.fact_orders COMPUTE STATISTICS FOR ALL COLUMNS;
