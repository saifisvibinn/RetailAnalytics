-- =============================================================================
-- Table: workspace.gold.daily_sales_summary
-- Grain: One row per sales_date x product_category
-- Primary Key: (sales_date, product_category)
-- =============================================================================

CREATE OR REPLACE TABLE workspace.gold.daily_sales_summary AS
SELECT 
    CAST(order_purchase_timestamp AS DATE) AS sales_date,
    product_category,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight
FROM workspace.gold.fact_orders
WHERE product_category IS NOT NULL
GROUP BY 
    CAST(order_purchase_timestamp AS DATE),
    product_category
ORDER BY sales_date DESC;

-- Delta Lake Physical Layout Optimization
OPTIMIZE workspace.gold.daily_sales_summary ZORDER BY (sales_date);

ANALYZE TABLE workspace.gold.daily_sales_summary COMPUTE STATISTICS FOR ALL COLUMNS;
