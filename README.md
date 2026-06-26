# End-to-End Airbnb Data Pipeline (AWS, dbt & Snowflake)

[![dbt version](https://img.shields.io/badge/dbt-1.11.x-orange.svg?style=flat-square&logo=dbt)](https://github.com/dbt-labs/dbt-core)
[![Snowflake](https://img.shields.io/badge/Snowflake-Data%20Warehouse-blue.svg?style=flat-square&logo=snowflake)](https://www.snowflake.com/)
[![AWS S3](https://img.shields.io/badge/AWS-S3-red.svg?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/s3/)
[![Architecture](https://img.shields.io/badge/Architecture-Medallion%20(Bronze--Silver--Gold)-green.svg?style=flat-square)](#data-pipeline-architecture-medallion-design)

An enterprise-grade analytics engineering project implementing a **Medallion Architecture** using **dbt (Data Build Tool)** and **Snowflake**. The pipeline processes raw Airbnb application data staged in AWS S3 and transforms it into highly optimized, analytical Star Schemas ready for BI tool consumption (Tableau, Dashboards) and Machine Learning features.

---

## 🏗️ Project Architecture Diagram

Below is the conceptual blueprint of the data flow and transformation stages:

![Project Architecture](assets/architecture_diagram.png)

> [!NOTE]  
> *To view this diagram locally, save your exported architecture image as `assets/architecture_diagram.png` in the root of the project.*



---

## 🚀 Key Engineering Highlights (Why this is Recruiter-Ready)

This project showcases production-level patterns for analytics engineering:

1. **Medallion Architecture**: Clear separation of concerns with **Bronze** (raw landing), **Silver** (cleansed/deduplicated), and **Gold** (analytical facts/dimensions) layers.
2. **Metadata-Driven SQL Generation**: Utilizes advanced dbt Jinja templating to perform **dynamic metadata-driven joins** in the Gold Layer (`obt.sql` & `fact.sql`), eliminating hardcoded, repetitive SQL.
3. **Slowly Changing Dimensions (SCD Type 2)**: Integrates dbt snapshots (`dim_bookings`, `dim_listings`, `dim_hosts`) to track historical state changes over time.
4. **Performance & Cost Optimization**: Configured with **Incremental Materializations** to minimize Snowflake warehouse compute usage by processing only modified records.
5. **Jinja Macro Libraries**: Custom macro utilities (`multiply`, `tag`, `trimmer`) to promote DRY (Don't Repeat Yourself) SQL development.
6. **Data Quality & Governance**: Implements automated schema-level testing and data validations.

---

## 📂 Repository Structure

```directory
.
├── aws_dbt_snowflake_project/      # Core dbt Project Directory
│   ├── dbt_project.yml             # Global configuration, schemas, & materializations
│   ├── profiles.yml                # Snowflake connection profiles (Dev/Prod settings)
│   ├── models/                     # Medallion layer transformations
│   │   ├── source/                 # Raw staging sources definition (YAML)
│   │   ├── bronze/                 # Raw landing tables (Incremental load)
│   │   ├── silver/                 # Business logic, type casts, and metrics tags
│   │   └── gold/                   # Analytical consumption layer (Facts & Dims)
│   │       └── ephemeral/          # CTE-based intermediate staging for dimensional joins
│   ├── macros/                     # Reusable Jinja-SQL utilities (DRY helper functions)
│   ├── snapshots/                  # dbt Snapshots tracking SCD Type 2 dimension states
│   └── tests/                      # Custom data quality tests
├── assets/                         # Documentation assets & architecture diagrams
├── pyproject.toml                  # Python dependency definitions (dbt-core, dbt-snowflake)
└── README.md                       # Main project documentation
```

---

## 🛠️ Data Pipeline Architecture (Medallion Design)

### 🥉 1. Bronze Layer (Raw Landing)
Data is loaded from the staging area directly as an exact replica of source records. 
* **Sources**: Configured in [sources.yml](aws_dbt_snowflake_project/models/source/sources.yml) pointing to raw Airbnb datasets (`listings`, `bookings`, `hosts`).
* **Materialization**: Configured as `incremental` in models such as [bronze_bookings.sql](aws_dbt_snowflake_project/models/bronze/bronze_bookings.sql).
* **Incremental Strategy**: Filters records based on `created_at` timestamp:
  ```sql
  {% if is_incremental() %}
      where created_at > (select coalesce(max(created_at), '1900-01-01') from {{ this }})
  {% endif %}
  ```

### 🥈 2. Silver Layer (Cleanse & Transform)
Applies structural cleansing, standardization, business rules enforcement, and deduplication.
* **Transforms**:
  * Formats host names by replacing white spaces with underscores (e.g. `HOST_NAME` in [silver_hosts.sql](aws_dbt_snowflake_project/models/silver/silver_hosts.sql)).
  * Classifies host response rates into categories (`VERY_GOOD`, `GOOD`, `FAIR`, `POOR`).
  * Classifies pricing tags (`low`, `medium`, `high`) using a custom macro [tag.sql](aws_dbt_snowflake_project/macros/tag.sql).
* **DRY Macros**:
  * `multiply(a, b, precision)`: Dynamically calculates total booking amounts inside [silver_bookings.sql](aws_dbt_snowflake_project/models/silver/silver_bookings.sql) using:
    ```sql
    {{ multiply('nights_booked', 'booking_amount', 2) }} as TOTAL_AMOUNT
    ```

### 🥇 3. Gold Layer (Fact & Dimensions - Star Schema)
The final consumption-ready analytical star schema layer.

* **Stage 1: Denormalized One Big Table (OBT)**:
  Implemented in [obt.sql](aws_dbt_snowflake_project/models/gold/obt.sql), this model uses a metadata configuration array and Jinja to programmatically build the complex LEFT JOIN statement. This metadata-driven approach reduces development complexity and makes extending the table as simple as modifying a config block.
  ```sql
  -- Snippet from obt.sql
  {% set configs = [
      { "table": "AIRBNB.SILVER.SILVER_BOOKINGS", "columns": "SILVER_BOOKINGS.*", "alias": "SILVER_bookings" },
      { "table": "AIRBNB.SILVER.SILVER_LISTINGS", "columns": "SILVER_listings.host_id, ...", "alias": "SILVER_listings", "join_condition": "SILVER_bookings.listing_id = SILVER_listings.listing_id" },
      ...
  ] %}
  ```

* **Stage 2: Ephemeral Models**:
  Within [gold/ephemeral/](aws_dbt_snowflake_project/models/gold/ephemeral/), models for `bookings.sql`, `hosts.sql`, and `listings.sql` prepare isolated records materialized as `ephemeral` (meaning they compile as inline Common Table Expressions - CTEs - in downstream queries rather than physically writing to tables).

* **Stage 3: Slowly Changing Dimensions (SCD Type 2)**:
  Configured in the [snapshots/](aws_dbt_snowflake_project/snapshots/) folder (e.g. [dim_listings.yml](aws_dbt_snowflake_project/snapshots/dim_listings.yml)), these capture historical changes in listings and hosts using a `timestamp` strategy. It updates `dbt_valid_to` to capture dynamic adjustments like host details or price shifts.

* **Stage 4: Final Fact Table**:
  [fact.sql](aws_dbt_snowflake_project/models/gold/fact.sql) represents the final Star Schema, utilizing metadata-driven joins between the OBT dataset and snapshot dimension tables (`DIM_LISTINGS`, `DIM_HOSTS`), delivering clean, versioned records for reporting.

---

## 🛠️ Reusable Macros Reference

To ensure high-quality coding practices, transformation logics are modularized into macros:

* **[multiply.sql](aws_dbt_snowflake_project/macros/multiply.sql)**: Computes rounded multiplications.
* **[tag.sql](aws_dbt_snowflake_project/macros/tag.sql)**: Conditionally tags numerical columns based on threshold values (e.g. low/medium/high pricing bounds).
* **[trimmer.sql](aws_dbt_snowflake_project/macros/trimmer.sql)**: Normalizes string inputs by trimming whitespaces and converting them to uppercase.

---

## 🏁 Getting Started & Setup

### 1. Prerequisites
- **Python**: version `3.12+`
- **Snowflake**: Active Snowflake warehouse access.
- **dbt**: Packages installed automatically via the project dependencies.

### 2. Installation
Install the project dependencies using `uv` (recommended) or standard `pip`:
```bash
# Clone the repository
git clone <repository-url>
cd AWS_DBT_Snowflake

# Install dependencies
uv sync
# Or
pip install -r pyproject.toml
```

### 3. Profiles Setup
Create/update your local profile setting at `~/.dbt/profiles.yml` or edit the included [profiles.yml](aws_dbt_snowflake_project/profiles.yml) for local development:
```yaml
aws_dbt_snowflake_project:
  outputs:
    dev:
      type: snowflake
      account: <your_snowflake_account_id>
      user: <your_username>
      password: <your_password>
      role: ACCOUNTADMIN
      database: AIRBNB
      warehouse: COMPUTE_WH
      schema: dbt_schema
      threads: 1
  target: dev
```

### 4. Running the Pipeline
Execute the following dbt commands in order to build, snapshot, and test your database:

```bash
# Navigate to the dbt project folder
cd aws_dbt_snowflake_project

# 1. Clean previous build artifacts
dbt clean

# 2. Run models (Bronze, Silver, Gold OBT and Fact Tables)
dbt run

# 3. Create historical Type-2 Snapshots (Gold Dimension snapshots)
dbt snapshot

# 4. Run data assertions and schema validation tests
dbt test
```

---

## 📊 Downstream Consumption
Once compiled, the Snowflake schema is organized for analytical use:
- **Tableau / BI Tools**: Point connections to the `AIRBNB.GOLD.FACT` and dimensions (`DIM_LISTINGS`, `DIM_HOSTS`) to compile revenue, booking growth, host response scores, and capacity metrics.
- **Machine Learning**: Ephemeral schemas and cleaned silver datasets act as the foundation for training feature-stores (e.g. price optimization algorithms, churn prediction).

---
*Developed with best practices in Analytics Engineering by Aswin.*
