# Retail Data Platform — Microsoft Fabric

I built this project around a retail business operating 200 stores. It uses synthetic point-of-sale data to support two needs: monitoring recent transactions and reporting on validated historical sales.

**Tools:** Microsoft Fabric, SQL Server, SQL, PySpark, Delta Lake, OneLake, Fabric Warehouse, Direct Lake, and Power BI.

## Business case

Sales transactions are stored in a central SQL Server database, while store and product details are maintained separately. Each invoice has a header and one or more lines. An invoice can start as `Pending` and later become `Completed` or `Cancelled`.

This creates two challenges: operational reporting needs current transaction statuses, while historical reporting needs clean, consistent sales figures. The processing logic also needs to handle later status changes and keep invalid records available for investigation.

[Read the full business case](docs/business-case.md).

## Synthetic dataset

I generated two months of retail data using [`Data_Generation.py`](scripts/Data_Generation.py), including controlled status changes and data-quality cases to test the processing logic.

| Data | January 2026 | February 2026 | Total |
| --- | ---: | ---: | ---: |
| Invoice headers | 308,269 | 276,468 | 584,737 |
| Invoice lines | 616,327 | 553,238 | 1,169,565 |

The master data includes **200 stores** and **100 products**. The generated data also includes **2,839 invoice status update events**, allowing me to test the incremental processing of existing invoices as well as new ones.

[See the full synthetic dataset reference](docs/synthetic-dataset-reference.md) for the monthly status counts, missing quantities, and controlled updates.

## Architecture

![Retail data platform architecture](assets/architecture/Fabric_Retail_Architecture.png)

The platform has two reporting paths:

- **Operational reporting:** SQL Server transactions are replicated through Fabric Mirroring and exposed through a Direct Lake semantic model, alongside curated store and product data from the Silver Lakehouse. A Power BI dashboard tracks recent transactions, order statuses, and store activity.
- **Historical reporting:** OneLake shortcuts provide access to mirrored transactions and CSV master data. PySpark notebooks validate and transform the data into Silver Delta tables. A Fabric Warehouse holds a Gold star schema for completed daily sales, which feeds a separate Power BI report.

## Data profiling and quality

Before building the Silver tables, I profiled the source data for missing values, duplicate keys, and broken relationships. The initial January checks found no orphan records in the tested source relationships. The main issue was missing quantities in invoice lines.

Across the generated January–February dataset:

- **58,719 invoice lines** had a missing `Quantity` and needed quarantine.
- **10,256 invoices** were left with no valid lines after those checks and also needed quarantine.

The rules keep problematic records traceable instead of silently dropping them. [Read the January profiling findings](docs/data-profiling.md) for the detailed dataset-level results, or see [`1_nb_data_profiling.ipynb`](notebooks/1_nb_data_profiling.ipynb) for the profiling queries.

## What I implemented

- Built the SQL Server source schema and generated transactions with controlled status changes.
- Processed initial and incremental data in PySpark using validation, quarantine, bounded watermarks, and Delta `MERGE`.
- Built a Gold warehouse star schema with date, store, and product dimensions. The daily sales fact is at **date + store + product** grain.
- Created separate Direct Lake semantic models and Power BI reports for operational and historical reporting.
- Demonstrated Delta Time Travel, 30-day retention on the Silver invoice headers, `OPTIMIZE` with `ZORDER`, and safe `VACUUM` dry-run inspection.

## Reports and data model

| Operational dashboard | Historical sales report |
| --- | --- |
| ![Operational dashboard](assets/reports/rep_operational_analytics.png) | ![Historical report](assets/reports/rep_historical_analytics.png) |

[Gold star schema](assets/modeling/gold_star_schema.png) · [Operational semantic model](assets/semantic_models/sm_operational_analytics.png) · [Historical semantic model](assets/semantic_models/sm_historical_analytics.png)

## Repository guide

- [`docs/`](docs/) — business case, synthetic dataset reference, and January data profiling findings.
- [`notebooks/`](notebooks/) — data profiling, initial load, incremental Bronze-to-Silver processing, Time Travel, and optimization.
- [`sql/`](sql/) — source SQL Server scripts and Fabric Warehouse schema, loads, and validation queries.
- [`scripts/`](scripts/) — synthetic retail data generator.
- [`assets/`](assets/) — architecture, dimensional model, semantic model, and report screenshots.
- [Bronze-to-Silver processing flowchart](assets/processing/bronze_silver_processing_flow.png) — initial and incremental load logic, validation, and quarantine.

**Project scope:** This is a portfolio implementation using synthetic data and controlled load runs, not a deployed production pipeline.
