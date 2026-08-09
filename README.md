# 🚀 Brazilian E-Commerce Analytics Platform
### End-to-End Enterprise Data Pipeline & BI Solution (Databricks + Power BI)

[![Databricks](https://img.shields.io/badge/Databricks-Serverless-red?logo=databricks)](https://databricks.com/)
[![Apache Spark](https://img.shields.io/badge/Apache%20Spark-3.x-orange?logo=apachespark)](https://spark.apache.org/)
[![Delta Lake](https://img.shields.io/badge/Delta%20Lake-Storage-blue?logo=delta)](https://delta.io/)
[![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-yellow?logo=powerbi)](https://powerbi.microsoft.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-blue?logo=python)](https://python.org)
[![SQL](https://img.shields.io/badge/SQL-ANSI%20%2F%20Spark-lightgrey?logo=postgresql)](https://spark.apache.org/docs/latest/sql-programming-guide.html)

---

## 📌 Executive Summary

This project implements an end-to-end, production-grade **Medallion Data Architecture** using **Databricks (Spark/Delta Lake)**, orchestrated via **Databricks Workflows**, and surfaced in an interactive **Power BI Sales & Logistics Dashboard**.

Using Kaggle's public **Olist Brazilian E-Commerce Dataset** (~100k orders from 2016 to 2018), this repository demonstrates modern Data Engineering & Business Intelligence standards:
1. **Medallion Architecture**: Landing → Bronze → Silver → Gold layers with clear separation of concerns.
2. **Data Modeling**: Star schema with 2 Fact tables (`fact_orders`, `fact_payments`) and 5 Dimension tables (`dim_date`, `dim_customer`, `dim_product`, `dim_sellers`, `dim_order_status`).
3. **Granularity & Fan-out Control**: Solved complex fan-out risks between item-level orders and payment lines through conformed dimensions (`dim_date`, `dim_order_status`).
4. **Automated Quality Engineering**: Built a 6-suite automated quality check notebook (`04_quality_checks`) enforcing primary key uniqueness, foreign key referential integrity, value range bounds, null thresholds, and layer revenue reconciliation.
5. **Delta Optimizations**: Applied file compaction (`OPTIMIZE`), multidimensional sorting (`ZORDER BY`), and table statistics (`ANALYZE TABLE`).
6. **Infrastructure as Code (IaC)**: Exported workflow pipeline definition for CI/CD readiness.

---

## 🏗️ System Architecture

```mermaid
flowchart TD
    subgraph Landing Layer ["1. Landing Layer (UC Volume)"]
        CSV["Kaggle Olist CSV Files\n/Volumes/workspace/retail_landing/raw_data/"]
    end

    subgraph Bronze Layer ["2. Bronze Layer (Delta - workspace.bronze)"]
        B_Orders["orders"]
        B_Items["order_items"]
        B_Payments["order_payments"]
        B_Customers["customers"]
        B_Products["products"]
        B_Sellers["sellers"]
        B_Meta["+ _ingestion_timestamp & _source_file"]
    end

    subgraph Silver Layer ["3. Silver Layer (Delta - workspace.silver)"]
        S_Orders["orders (Typed & Standardized)"]
        S_Items["order_items (Composite Dedup)"]
        S_Payments["order_payments (Composite Dedup)"]
        S_Customers["customers (Initcap Cities)"]
        S_Products["products (Enriched with English Translation)"]
        S_Sellers["sellers"]
    end

    subgraph Gold Layer ["4. Gold Layer (Delta - workspace.gold)"]
        G_FactOrders["fact_orders\n(Order-Item Grain: 113,425 rows)"]
        G_FactPayments["fact_payments\n(Payment-Line Grain: 103,886 rows)"]
        G_DimDate["dim_date (1,096 rows)"]
        G_DimCust["dim_customer (96,096 unique customers)"]
        G_DimProd["dim_product (32,951 products)"]
        G_DimSeller["dim_sellers (3,095 sellers)"]
        G_DimStatus["dim_order_status (8 valid statuses)"]
    end

    subgraph Quality Layer ["5. Automated Quality Checks (04_quality_checks)"]
        QC1["1. PK Uniqueness Test"]
        QC2["2. Null Rate Thresholds"]
        QC3["3. FK Referential Integrity"]
        QC4["4. Value Range Bounds"]
        QC5["5. Table Row Thresholds"]
        QC6["6. Layer Revenue Reconciliation"]
    end

    subgraph BI Layer ["6. Power BI Desktop"]
        PBI["Star Schema Dashboard\n(Direct import via Databricks SQL Warehouse)"]
    end

    CSV -->|00_setup & 01_bronze| Bronze Layer
    Bronze Layer -->|02_silver| Silver Layer
    Silver Layer -->|03_gold| Gold Layer
    Gold Layer -->|04_quality_checks| Quality Layer
    Gold Layer -->|Direct Import| PBI
```

---

## 📁 Repository Structure

```text
├── notebooks/
│   ├── 00_setup.py            # Download Kaggle dataset to Databricks UC Volume
│   ├── 01_bronze.py           # Raw ingestion to Delta format + metadata columns
│   ├── 02_silver.py           # Type casting, text cleaning, composite key dedup & joins
│   ├── 03_gold.py             # Star schema construction & Delta ZORDER optimizations
│   └── 04_quality_checks.py   # 6-suite automated data quality assertion framework
├── sql/
│   ├── gold_fact_orders.sql   # SQL definition for fact_orders
│   ├── gold_fact_payments.sql # SQL definition for fact_payments
│   └── gold_dimensions.sql    # SQL definitions for all dimension tables
├── docs/
│   ├── pipeline_audit_report.md  # Detailed 19-section data model & technical audit
│   ├── dim_order_status_report.md # Shared order status dimension validation report
│   └── powerbi_dashboard_reference.md # DAX measures & visual design specification
├── workflows/
│   └── retail_nightly_pipeline.yml # Databricks Workflow Job definition (IaC)
└── README.md
```

---

## 📊 Gold Star Schema & Data Model

The data model follows strict Kimball Star Schema principles to ensure fast query performance and prevent double-counting in Power BI:

```
                            dim_date          dim_order_status
                           /   |   \           /          \
                          /    |    \         /            \
        daily_sales_summary  fact_orders   fact_payments
                           /    |    \
                          /     |     \
                 dim_customer dim_product dim_sellers
```

### Table Specifications

| Table Name | Layer | Primary Key | Grain | Verified Row Count |
|---|---|---|---|---|
| `fact_orders` | Gold | `(order_id, order_item_id)` | One row per order item | 113,425 |
| `fact_payments` | Gold | `(order_id, payment_sequential)` | One row per payment line | 103,886 |
| `dim_customer` | Gold | `customer_unique_id` | One row per unique customer | 96,096 |
| `dim_product` | Gold | `product_id` | One row per product | 32,951 |
| `dim_sellers` | Gold | `seller_id` | One row per seller | 3,095 |
| `dim_date` | Gold | `date_key` | One row per calendar date | 1,096 |
| `dim_order_status` | Gold | `order_status` | One row per status | 8 |
| `daily_sales_summary` | Gold | `(sales_date, product_category)` | Aggregate date x category | Varies |

> ⚠️ **Key Modeling Insight**: In Olist, `customer_id` is unique per *order* (~99,441), while `customer_unique_id` represents the *actual human customer* (~96,096). Using `customer_unique_id` prevents a **3.5% overcount** in Customer KPIs.

---

## 🛡️ Automated Data Quality Assurance

The `04_quality_checks` notebook executes 6 automated test suites after every pipeline run:

| Suite | Description | Verification Logic | Status |
|---|---|---|---|
| **1. Primary Key Uniqueness** | Verifies no duplicate rows exist for any entity | `COUNT(*) == COUNT(DISTINCT PK)` across all 7 Gold tables | ✅ PASS |
| **2. Null Rate Thresholds** | Ensures mandatory columns are never null | Checks `order_id`, `customer_unique_id`, `price` (<5% threshold) | ✅ PASS |
| **3. FK Referential Integrity** | Prevents orphan records between facts and dimensions | Foreign keys in facts exist in `dim_customer`, `dim_product`, `dim_sellers`, `dim_order_status` | ✅ PASS |
| **4. Value Range Bounds** | Catches illegal data values | Scans for negative prices, negative shipping, or future dates | ✅ PASS |
| **5. Table Row Thresholds** | Prevents empty table generation | Validates row counts against minimum expected operational baselines | ✅ PASS |
| **6. Layer Reconciliation** | Ensures zero financial data loss | Reconciles `SUM(price)` and `SUM(payment_value)` between Silver & Gold | ✅ PASS |

---

## ⚡ Delta Lake Optimizations

To ensure instant dashboard responsiveness in Power BI, physical data layout optimizations are applied to Gold Delta tables:

```sql
-- Compact small files and physically sort data by high-cardinality filter columns
OPTIMIZE workspace.gold.fact_orders 
ZORDER BY (order_purchase_date, customer_state);

OPTIMIZE workspace.gold.fact_payments 
ZORDER BY (order_purchase_date, payment_type);

-- Refresh column-level statistics for the Spark cost-based query optimizer (CBO)
ANALYZE TABLE workspace.gold.fact_orders COMPUTE STATISTICS FOR ALL COLUMNS;
ANALYZE TABLE workspace.gold.fact_payments COMPUTE STATISTICS FOR ALL COLUMNS;
```

---

## 📈 Power BI Measures & DAX Reference

| KPI / Metric | DAX Expression | Description |
|---|---|---|
| **Total Revenue** | `Total Revenue = SUM(fact_orders[price])` | Sum of item sale prices |
| **Total Orders** | `Total Orders = DISTINCTCOUNT(fact_orders[order_id])` | Distinct orders (prevents item-level overcount) |
| **Total Customers** | `Total Customers = DISTINCTCOUNT(fact_orders[customer_unique_id])` | True distinct human customers |
| **Average Order Value (AOV)** | `AOV = DIVIDE([Total Revenue], [Total Orders], 0)` | Average revenue generated per order |
| **Total Payments** | `Total Payment Value = SUM(fact_payments[payment_value])` | Sum of customer payments (Price + Freight) |
| **Delivery Rate** | `Delivery Rate = DIVIDE(CALCULATE([Total Orders], dim_order_status[order_status] = "delivered"), [Total Orders], 0)` | Percentage of completed deliveries |
| **Avg Delivery Days** | `Avg Delivery Days = AVERAGE(fact_orders[delivery_days])` | Mean transit duration in days |

---

## 🔄 Orchestration & Automation

The entire pipeline is automated via Databricks Workflows (`Retail_Nightly_Pipeline`):

1. **`00_setup`** — Data pull & directory staging
2. **`01_bronze`** — Ingestion into Delta lakehouse
3. **`02_silver`** — Deduplication, schema enforcement, enrichment
4. **`03_gold`** — Star schema aggregation & Z-Ordering
5. **`04_quality_checks`** — Quality assertions & threshold validation

---

## 🛠️ How to Deploy & Run

### Prerequisites
- Databricks Workspace (Serverless or Unity Catalog enabled)
- Databricks SQL Warehouse (for Power BI connection)
- Power BI Desktop

### Installation Steps
1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/your-username/brazilian-ecommerce-pipeline.git
   ```
2. Import the `notebooks/` directory into your Databricks Workspace.
3. Execute `00_setup` to download the Kaggle dataset to Unity Catalog Volumes.
4. Execute `01_bronze`, `02_silver`, `03_gold`, and `04_quality_checks` sequentially.
5. In Power BI Desktop:
   - Connect via **Databricks Partner Connect** / **Databricks SQL Connector**.
   - Select `workspace.gold` schema and import all 7 tables.
   - Configure relationships as specified in the [Data Model section](#-gold-star-schema--data-model).

---

## 📄 License & Attribution
- Data Source: [Olist Brazilian E-Commerce Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- License: MIT License
