# Casper Data Ingestion & Transformation Pipeline

A complete end-to-end data pipeline for the Casper health and wellness platform. This project combines **Python-based data ingestion** with **SQL-based data transformation** using dbt to create clean, aggregated analytics datasets.

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Tech Stack](#tech-stack)
4. [Repository Structure](#repository-structure)
5. [Setup & Installation](#setup--installation)
6. [Running the Pipeline](#running-the-pipeline)
7. [Component Details](#component-details)
8. [Data Flow](#data-flow)
9. [Assumptions & Design Decisions](#assumptions--design-decisions)
10. [Future Enhancements](#future-enhancements)
11. [Documentation & Metadata](#documentation--metadata)
12. [Monitoring](#monitoring)
13. [Tradeoffs](#tradeoffs)
14. [Troubleshooting](#troubleshooting) 

---

## 🎯 Project Overview

This pipeline ingests health and wellness data from CSV files, loads it into Google BigQuery, and performs multi-layer transformations to produce clean, business-ready analytics datasets.

**High-level workflow:**
```
Raw CSV Files
    ↓
Step 1: Python Ingestion (Jupyter Notebook)
    ↓
Google BigQuery (Raw Data Layer)
    ↓
Step 2: dbt SQL Transformation (3-layer architecture)
    ↓
BigQuery Analytics Tables (Ready for BI tools, dashboards, reports)
```

---

## 🏗️ Architecture

### Three-Layer Transformation Model

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Raw Data                                           │
│ (BigQuery: casper_data_raw)                                 │
│ - patients, steps, exercises (CSV → BigQuery)               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓ (dbt run)
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Curated Data                                       │
│ (BigQuery: dbt models in dbt_casper schema)                 │
│ - Type casting, trimming, deduplication                     │
│ - patients_curated, steps_curated, exercises_curated        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓ (dbt run)
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Reporting/Aggregation                              │
│ (BigQuery: dbt models in dbt_casper schema)                │
│ - Business logic, aggregations, KPIs                       │
│ - patients_engagement_reporting                             │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Data Ingestion** | Python 3.8+, Pandas, Google BigQuery SDK | Load CSV → BigQuery |
| **Data Warehouse** | Google BigQuery (BigQuery) | Central data repository |
| **Data Transformation** | dbt (data build tool) + SQL | Transform raw → analytics |
| **Database Adapter** | dbt-bigquery | dbt ↔ BigQuery connection |
| **Orchestration** | Jupyter Notebook | Interactive Python workflows |
| **Version Control** | Git | Code management |

---

## 📁 Repository Structure

```
dbt_casper/
│
├── README.md                           # This file - full project documentation
├── README_PIPELINE.md                  # Detailed dbt pipeline documentation
├── casper_data_ingestion.ipynb         # Step 1: Python data ingestion script
│
├── dbt_casper/                         # Main dbt project folder
│   ├── dbt_project.yml                 # dbt configuration & settings
│   ├── profiles.yml                    # BigQuery connection profile
│   ├── requirements.txt                # Python dependencies (dbt + adapter)
│   │
│   ├── models/
│   │   ├── sources.yml                 # Raw data source definitions
│   │   │
│   │   ├── casper_data_curated/        # Layer 2: Curated/Cleaned models
│   │   │   ├── _casper_data_curated_docs.yml
│   │   │   ├── patients_curated.sql
│   │   │   ├── steps_curated.sql
│   │   │   └── exercises_curated.sql
│   │   │
│   │   └── casper_data_reporting/      # Layer 3: Reporting/Analytics models
│   │   |   ├── _casper_data_reporting_docs.yml
│   │   |   └── patients_engagement_reporting.sql
|   |   |
│   │   └── sample_incremental_pipeline/  # Sample incremental models for demonstration
│   │       ├── patients_engagement_incremental.sql
│   │       ├── sample_exercise_incremental.sql
│   │       ├── sample_patients_incremental.sql
│   │       └── sample_steps_incremental.sql
│   │
│   ├── seeds/                          # Static reference data (CSV → dbt) for sample incremental models
│   │   ├── sample_patients.csv
│   │   ├── sample_exercises.csv
│   │   └── sample_steps.csv
│   │
│   ├── tests/                          # dbt data quality tests
│   ├── macros/                         # Reusable SQL functions/macros
│   ├── snapshots/                      # SCD Type 2 snapshots (change tracking)
│   ├── analyses/                       # Ad-hoc SQL analyses
│   ├── logs/                           # dbt execution logs
│   └── target/                         # Generated artifacts (compiled SQL, manifest)
│
├── bonus_llm_task/                     # Bonus: LLM-powered document generation
│   └── doc_generator.py                # Python script using Copilot API
│
├── raw_data/                           # Input: Raw CSV data files provided by Casper
│   ├── patients.csv                    # Patient demographics
│   ├── exercises.csv                   # Exercise activity data
│   └── steps.csv                       # Step count data
│
├── logs/
│   └── query_log.sql                   # Query execution logs
│
└── [other workspace files]
```

---

## 🚀 Setup & Installation

### Prerequisites

- **Python 3.8+** installed
- **Google Cloud account** with BigQuery access
- **dbt** CLI (installed via pip)
- **Git** for version control
- **Service account credentials** (JSON key file from Google Cloud)

### Step 1: Install Dependencies

```bash
# Navigate to dbt project
cd dbt_casper

# Install Python packages (dbt + BigQuery adapter)
pip install -r requirements.txt
```

**Contents of `requirements.txt`:**
```
dbt-bigquery
```

### Step 2: Set Up Google Cloud Credentials

1. Create BigQuery Service Account
2. Go to Google Cloud Console
3. IAM & Admin → Service Accounts
4. Create new service account
5. Grant roles:
    - BigQuery Data Editor
    - BigQuery Job User
    - Bigquery User
6. Generate JSON key
7. Download and save key file securely (not to be commited or shared publically)

### Step 3: Configure dbt

Update [dbt_casper/profiles.yml](dbt_casper/profiles.yml) with your BigQuery connection details:

```yaml
dbt_casper:
  outputs:
    dev:
      dataset: casper_data_raw
      job_execution_timeout_seconds: 300
      job_retries: 1
      keyfile: YOUR JSON KEY
      location: EU
      method: service-account
      priority: interactive
      project: casper-code-challenge
      threads: 10
      type: bigquery
```
- profiles.yml file stored here for download. Please add your json key.

### Step 4: Verify Connection

```bash
dbt debug
```

Expected output:
```
Connection test: [OK]
```

---

## ▶️ Compiling and Running the Pipeline

### Full Pipeline (Recommended)

```bash
# Step 1: Ingest raw data (Python)
# Open and run: casper_data_ingestion.ipynb
# This loads CSV files from raw_data/ into BigQuery

# Step 3: Transform data (dbt)
dbt compile 

# Step 3: Transform data (dbt)
dbt run 

# Step 4: Run data quality tests
dbt test

# Step 5: Generate documentation
dbt docs generate
dbt docs serve  # Opens web UI at http://localhost:8000
```

### Individual Steps

```bash
# Compile specific model
dbt compile --select model_name --target target_env

dbt compile --select patients_engagement_reporting --target prod

# Run specific model
dbt run --select model_name --target target_env

dbt run --select patients_engagement_reporting --target prod

# Test specific model
dbt test --select model_name --target target_env

dbt test --select patients_engagement_reporting --target prod

# Run with detailed logging
dbt run --debug

# Dry run (shows what would execute)
dbt run --dry-run
```

---

## 📊 Component Details

### 1. Data Ingestion Layer: `casper_data_ingestion.ipynb`

**Purpose:** Load raw CSV data into BigQuery

**How it works:**

```python
# Install dependencies
%pip install pandas google-cloud-bigquery pyarrow

# Import libraries
import pandas as pd
from google.cloud import bigquery
from google.oauth2 import service_account

# Set configuration
project_id = "casper-code-challenge"
dataset_id = "casper_data_raw"
credentials_path = r"C:\path\to\service-account-key.json"
data_dir = r"C:\path\to\raw_data"

# Initialize BigQuery client
credentials = service_account.Credentials.from_service_account_file(credentials_path)
client = bigquery.Client(project=project_id, credentials=credentials, location="EU")

# Load CSV files
#### Full code in the `casper_data_ingestion.ipynb` file
```

**Key Features:**
- ✅ Reads all CSV files from `raw_data/` folder
- ✅ Auto-detects column types (schema inference)
- ✅ Replaces existing tables (idempotent)
- ✅ Uses service account for authentication
- ✅ Handles Pandas DataFrames natively

**Output:**
- Creates/updates tables in BigQuery dataset `casper_data_raw`:
  - `casper_data_raw.patients`
  - `casper_data_raw.exercises`
  - `casper_data_raw.steps`

**Dependencies:**
- `pandas`: Data manipulation
- `google-cloud-bigquery`: BigQuery SDK
- `pyarrow`: Data serialization
- Service account credentials (JSON file)

---

### 2. Transformation Layer: dbt SQL Models

**Location:** [dbt_casper/models/](dbt_casper/models/)

**Three-layer architecture:**

#### Layer 2a: Curated/Cleaned Models

**File:** [dbt_casper/models/casper_data_curated/](dbt_casper/models/casper_data_curated/)

The curated layer performs **data cleaning, type casting, and deduplication**. All models in this layer are materialized as tables for performance.

##### `patients_curated.sql`

**Transformations:**
- Trims whitespace from text fields
- Renames columns to snake_case
- Deduplicates by `patient_id` (keeps first occurrence)

**Output:** Materialized table for fast queries

---

##### `steps_curated.sql` & `exercises_curated.sql`

Similar structure with:
- Type casting (STEPS → int64, MINUTES → float64)
- Timestamp casting
- Deduplication (keeps latest version by `updated_at`)

---

#### Layer 2b: Reporting/Analytics Models

**File:** [dbt_casper/models/casper_data_reporting/patients_engagement_reporting.sql](dbt_casper/models/casper_data_reporting/patients_engagement_reporting.sql)

The reporting layer performs **aggregation and applies business logic** to create analytical datasets.

The reporting layer performs **aggregation and applies business logic** to create analytical datasets.

### 2b.1 `patients_engagement_reporting`

**Purpose:** Aggregate patient health engagement metrics for reporting and analysis.

**Business Logic:**

1. **Steps to Minutes Conversion:**
   - Business rule: 1 step = 0.002 generated minutes
   - Aggregates total step-derived minutes per patient

2. **Exercise Minutes Aggregation:**
   - Sums exercise minutes per patient
   - Exercise minutes are already expressed in minutes

3. **Total Engagement Minutes:**
   - Combines steps-derived minutes + exercise minutes
   - Rounds to 2 decimal places

**Output Columns:**
- `patient_id` (PK): Unique patient identifier
- `first_name`: Patient first name
- `last_name`: Patient last name
- `country`: Patient country (used for clustering/partitioning)
- `total_minutes`: Total engagement in minutes (rounded to 2 decimals)

**Performance Optimization:**
- Clustered by `country` for faster filtering and aggregation by geography

**Relationships:**
- Performs `LEFT JOIN` with `steps_curated` and `exercises_curated` to handle patients with no activity

---

### 2c Core question:  Which patient(s) generated the most total minutes, combining both steps and exercise activity?

Sql Query

```sql
select *,
from `casper-code-challenge.casper_data_reporting.patients_engagement_reporting`
qualify rank() over (order by total_minutes desc) = 1
```

---

### 4. Data Cleanup & Deduplication Strategy

#### Deduplication Approach

All curated models handle duplicate records using the same pattern:

```sql
with deduplication as (
  select
    *,
    row_number() over (
        partition by [PRIMARY_KEY]
        order by [TIMESTAMP_COLUMN] desc  -- or asc
    ) as row_num
  from [source_data]
)

select * from deduplication
where row_num = 1
```

**Logic:**
- Uses `ROW_NUMBER()` window function to assign a rank to each record within a partition
- Keeps only the record where `row_num = 1` (eliminates duplicates)
- Ordering strategy:
  - `patients_curated`: Ordered by `patient_id` (ascending) - keeps first occurrence
  - `steps_curated`: Ordered by `updated_at` (descending) - keeps latest version
  - `exercises_curated`: Ordered by `exercise_updated_at` (descending) - keeps latest version

---

## 5. Data Quality & Testing

Each model includes basic dbt tests to ensure data quality:

**Location:** [dbt_casper/models/casper_data_curated/_casper_data_curated_docs.yml](dbt_casper/models/casper_data_curated/_casper_data_curated_docs.yml)

```yaml
models:
  - name: patients_curated
    columns:
      - name: patient_id
        tests:
          - unique    # No duplicate patient IDs
          - not_null  # Every patient must have an ID
```
### Primary Key Tests
- `unique`: Ensures primary keys have no duplicates
- `not_null`: Ensures primary keys are always populated

**Models with Tests:**
- `exercises_curated.exercise_id` - unique, not_null
- `patients_curated.patient_id` - unique, not_null
- `steps_curated.steps_id` - unique, not_null
- `patients_engagement_reporting.patient_id` - unique, not_null

---

### 6. dbt Configuration Files

#### `dbt_project.yml`

Central dbt configuration:
```yaml
name: 'dbt_casper'
version: '1.0.0'
config-version: 2
profile: 'casper_dbt'

model-paths: ["models"]
test-paths: ["tests"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]
seed-paths: ["seeds"]
analysis-paths: ["analyses"]

target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"
```

#### `profiles.yml`

BigQuery connection details (update with your credentials):
```yaml
dbt_casper:
  outputs:
    dev:
      dataset: casper_data_raw
      job_execution_timeout_seconds: 300
      job_retries: 1
      #keyfile: 'PATH TO JSON KEY'
      location: EU
      method: service-account
      priority: interactive
      project: casper-code-challenge
      threads: 10
      type: bigquery
```

#### `sources.yml`

Defines raw data sources:
```yaml
version: 2

sources:
  - name: casper_data_raw
    database: casper-code-challenge
    schema: casper_data_raw
    tables: 
      - name: exercises
      - name: patients
      - name: steps
```

---

## 🔄 Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. RAW CSV FILES                                                    │
│    raw_data/patients.csv                                            │
│    raw_data/exercises.csv                                           │
│    raw_data/steps.csv                                               │
└──────────────────────────────────┬──────────────────────────────────┘
                                   │
                    ┌──────────────► [casper_data_ingestion.ipynb]
                    │               (Python + Pandas + BigQuery SDK)
                    │
┌───────────────────▼──────────────────────────────────────────────────┐
│ 2. BIGQUERY RAW LAYER (casper_data_raw)                              │
│    patients      | exercises      | steps                            │
│                  |                |                                  │
│    PATIENT_ID    | ID             | ID                               │
│    first_name    | EXTERNAL_ID    | EXTERNAL_ID                      │
│    last_name     | MINUTES        | STEPS                            │
│    country       | COMPLETED_AT   | SUBMISSION_TIME                  |
|                  │ UPDATED_AT     | UPDATED_AT                       |
└──────────────────────┬───────────────────────────────────────────────┘
                       │
         ┌─────────────► [dbt run] ◄─────────────┐
         │                                       │
         │               SQL Transformations:    │
         │               - Type casting          │
         │               - Trimming              │
         │               - Deduplication         │
         │                                       |
┌────────▼───────────────────────────────────────────────────────────┐
│ 3. BIGQUERY CURATED LAYER (dbt_casper schema)                      │
│    patients_curated    | exercises_curated    | steps_curated      │
│                        |                      |                    │
│    patient_id [PK]     | exercise_id [PK]     | steps_id [PK]      │
│    first_name          | patient_id [FK]      | patient_id [FK]    │
│    last_name           | exercise_minutes     | step_count         │
│    country             | exercise_completed_at| submission_time    | 
|                        │ exercise_updated_at  | updated_at         |
└──────────────────────────┬─────────────────────────────────────────┘
                           │
         ┌─────────────────► [dbt run] ◄────────────┐
         │                                          │
         │               Business Logic:            │
         │               - Aggregation              │
         │               - Joins                    │
         │               - Calculations             │
         │                                          |
┌────────▼───────────────────────────────────────────────────────────┐
│ 4. BIGQUERY REPORTING LAYER (dbt_casper schema)                    │
│    patients_engagement_reporting                                   │
│    (100 rows - one per patient) E.g.                                    │
│    patient_id | first_name | last_name | country | total_minutes   │
│    ─────────────────────────────────────────────────────────────   │
│    P001       | John       | Doe       | UK      | 45.50           │
│    P002       | Jane       | Smith     | US      | 120.30          │
│    ...                                                             │
└────────────────────────────────────────────────────────────────────┘
                           │
                           ▼
               ┌───────────────────────┐
               │ BI Tools / Dashboards │
               │ Reports / Notebooks   │
               │ Analytics Apps        │
               └───────────────────────┘
```

---

## 💡 Assumptions & Design Decisions

| Assumption | Rationale |
|-----------|-----------|
| **BigQuery as data warehouse** | Scalable, serverless, integrates with dbt seamlessly |
| **Service account authentication** | Secure, non-interactive, suitable for CI/CD pipelines |
| **WRITE_TRUNCATE in ingestion** | Idempotent: safe to run multiple times without duplicates |
| **Materialized tables** | Faster reporting queries vs. views (trade off storage) |
| **Deduplication in Layer 2** | Handles upstream data quality issues early in pipeline |
| **Three-layer architecture** | Separation of concerns: raw → clean → analytics |
| **LEFT JOIN in reporting** | Preserves patients with no activity (no data loss) |
| **Clustering by country** | Optimizes queries filtering or grouping by geographic region |
| **1 step = 0.002 minutes** | Business rule materialized in SQL. Step-to-minute conversion is materialized for consistency |

---

## Future Enhancements

### `sample_incremental_pipeline/`

This folder contains models for incremental data loading:
- `sample_patients_incremental.sql`
- `sample_exercises_incremental.sql`
- `sample_steps_incremental.sql`
- `patients_engagement_incremental.sql`

These models use dbt's incremental materialization to load only new or changed records, reducing compute time and database load for large datasets.
These models remain untested due to the Bigquery Free Tier limitations. The free tier does not allow to run DML commands. This section is just to provide the basic idea about the code structure to make pipeline incremental and reduce processing time and cost.

---

## Documentation & Metadata

All models include YAML documentation with:
- Model descriptions
- Column descriptions
- Data quality tests
- Persist docs configuration (stores descriptions in database)

**View documentation:**
- Generated YAML: `models/casper_data_curated/_casper_data_curated_docs.yml`
- Generated YAML: `models/casper_data_reporting/_casper_data_reporting_docs.yml`

---

## Monitoring

### Check Model Lineage
```bash
dbt docs generate && dbt docs serve
```
Navigate to the lineage graph to see data flow.

### Review Compiled SQL
```
target/compiled/dbt_casper/models/
```
View the actual SQL that dbt generates before execution.

## ⚖️ Tradeoffs

| Tradeoff | Decision | Why |
|----------|----------|-----|
| **Storage vs. Query Speed** | Materialized tables (use more storage) | Reporting queries must be fast for dashboards |
| **ETL Automation vs. Flexibility** | Jupyter notebook + manual dbt run | Interactive development + control, sacrifices automation |
| **Schema Inference vs. Strict Schema** | autodetect=True in BigQuery load | Faster setup, assumes well-formed CSVs |
| **Deduplication Strategy** | ROW_NUMBER() + partition | Transparent, debugging-friendly vs. complex window functions |
| **Cost vs. Real-time** | Batch processing (daily runs assumed) | Lower cost than streaming, acceptable latency for analytics |
| **Data Retention** | WRITE_TRUNCATE (replace, not append) | Simplicity, assumes source of truth is raw CSVs |

---

## 🔧 Troubleshooting

### Issue: `ImportError: No module named 'google.cloud'`

**Solution:**
```bash
%pip install google-cloud-bigquery
```

### Issue: `Permission denied` when loading data to BigQuery

**Solution:**
- Verify service account has BigQuery editor role
- Check credentials JSON path is correct
- Ensure dataset `casper_data_raw` exists

### Issue: dbt debug fails with connection error

**Solution:**
```bash
# Verify credentials path in profiles.yml
dbt debug

# Ensure service account key file exists
ls -la /path/to/service-account-key.json
```

### Issue: dbt tests fail

**Solution:**
```bash
# Run tests with verbose output
dbt test --debug

# Check for missing columns or data quality issues
dbt test --select patients_curated
```

### Issue: Duplicate rows in output

**Solution:**
The deduplication logic in Layer 2 should handle this. Verify:
```sql
-- Check for duplicates in raw layer
SELECT patient_id, count(*) as cnt 
FROM `casper-code-challenge.casper_data_raw.patients`
GROUP BY patient_id 
HAVING cnt > 1
```

---

## 📚 Additional Resources

- **dbt Documentation:** https://docs.getdbt.com/
- **BigQuery SQL Syntax:** https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax
- **Google Cloud BigQuery Python Client:** https://cloud.google.com/bigquery/docs/reference/python
- **dbt-bigquery Adapter:** https://docs.getdbt.com/reference/warehouse-setups/bigquery-setup

---

## 📝 Notes

- See [README_PIPELINE.md](README_PIPELINE.md) for detailed dbt model documentation
- Raw data CSVs are source of truth; BigQuery tables are generated artifacts
- All transformations are SQL-based (no Python transforms in analytics layer)
- dbt provides single source of truth for transformation logic

---

## ⚡ Quick Start Checklist

- [ ] Install Python 3.8+
- [ ] Clone repository
- [ ] Install dependencies: `%pip install -r dbt_casper/requirements.txt`
- [ ] Download Google Cloud service account key
- [ ] Update `dbt_casper/profiles.yml` with credentials
- [ ] Run: `dbt debug` (verify connection)
- [ ] Run: `casper_data_ingestion.ipynb` (load CSV data)
- [ ] Run: `dbt run` (transform data)
- [ ] Run: `dbt test` (verify data quality)
- [ ] Run: `dbt docs serve` (view documentation)

---

**Documentation** Generated by Copilot. Proof read by Preetika Jain
**Prompt Submitted** You are a document assistant.
This repository consists of the end to end project for Casper health and wellness platform. Read the files and folders tog enerate a README.md in Markdown that explains:
    - Purpose of the model
    - Data Ingestion
    - Main transformations
    - Key business logic and metrics
    - Data flow
    - dbt, Bigquery setup
    - Future Enhancements
    - Any assumptions or caveats
    - Tradeoffs
    - and more
Output ONLY Markdown.
**Last Updated:** 2026-08-17  
**Status:** Production Ready ✅
