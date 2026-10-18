# Data Profiling

[← Back to main README](../README.md)

## Profiling Scope

This document summarizes the January 2026 initial-load profiling snapshot captured in the [profiling notebook](../notebooks/1_nb_data_profiling.ipynb),
before February transactions and subsequent header status updates were applied.
 
The saved outputs represent that initial state. Rerunning the notebook against
the current Bronze layer may produce different results as the source data evolves.

### _Stores_

> **Profiling Summary:**
> - **Total Records:** 200 store records were profiled.
> - **Primary Key Quality:** `StoreID` is 100% unique with no NULL or invalid values detected.
> - **Completeness:** No missing values were detected in `StoreID`, `StoreName`, `Region`, or `City`.
> - **Categorical Review:** Distinct `Region` and `City` values were reviewed for suspicious variations, with no issues identified.
> - **Readiness:** Based on the profiling checks performed, the dataset is considered suitable for Silver-layer ingestion.

### *_Products_*

> **Profiling Summary:**
> - **Total Records:** 100 product records were profiled.
> - **Primary Key Quality:** `ProductID` is 100% unique with no NULL or invalid values detected.
> - **Completeness:** No missing values were detected across the profiled product columns.
> - **Category Coverage:** Four distinct product categories were identified and reviewed for suspicious variations.
> - **Unit Price Quality:** `UnitPrice` values range from `25.15` to `979.72`, with no missing or invalid values detected.
> - **Price Consistency:** At the time of profiling, `UnitPrice` values in the transaction lines matched the corresponding prices in the product master data, with no price discrepancies detected.
> - **Readiness:** Based on the profiling checks performed, the dataset is considered suitable for Silver-layer ingestion.

### *_Invoices Header_*

> **Profiling Summary:**
> - **Total Records:** 308,269 invoice header records were profiled.
> - **Primary Key Quality:** `InvoiceID` is 100% unique with no NULL values detected.
> - **Store Reference Quality:** No missing or invalid `StoreID` values were detected, with 200 distinct stores represented.
> - **Date Coverage:** `InvoiceDate` contains no missing values and spans from January 1 to January 31, 2026, confirming the expected initial-load period.
> - **Payment Methods:** Three distinct payment methods were identified—Cash, Credit Card, and Wallet—with no missing values detected.
> - **Order Status:** No missing OrderStatus values were detected. The dataset contains 302,029 Completed, 4,687 Cancelled, and 1,553 Pending records.
> - **Modification Baseline:** `LastModifiedAt` matches `InvoiceDate` for all invoice headers, confirming that no post-creation header updates had occurred at the time of January profiling.
> - **Readiness:** Based on the profiling checks performed, the dataset is considered suitable for Silver-layer ingestion.

### *_Invoice Lines_*

> **Profiling Summary:**
> - **Total Records:** 616,327 invoice line records were profiled.
> - **Primary Key Quality:** `LineID` is 100% unique with no NULL values detected.
> - **Invoice References:** No missing `InvoiceID` values were detected, with 308,269 distinct invoices represented.
> - **Product References:** No missing or invalid `ProductID` values were detected, with 100 distinct products represented.
> - **Quantity Quality:** 31,199 records contain missing `Quantity` values, representing approximately 5% of the dataset. Valid quantities range from 1 to 4, with no zero or negative values detected.
> - **Unit Price Quality:** No missing or invalid `UnitPrice` values were detected, with 100 distinct unit prices represented.
> - **Product Master Consistency:** At the time of profiling, transaction-line `ProductID` and `UnitPrice` values matched the corresponding product master data, with no price discrepancies detected.
> - **Business Impact:** After excluding lines with missing `Quantity`, 5,536 invoice headers would have no analytically valid line items and therefore would not be considered business-ready.
> - **Quarantine Rule:** Lines with missing `Quantity` require direct quarantine. An invoice header remains valid if at least one valid line remains; headers with zero valid lines require indirect quarantine.
> - **Readiness:** The dataset is suitable for controlled Silver-layer processing, with missing `Quantity` values requiring controlled validation and handling before analytical use.

### *_Referential Integrity & Relationship Coverage Findings_*

> **Referential Integrity & Relationship Coverage Findings:**
> - **Stores Without Transactions:** No stores without invoice activity were detected during the analyzed period.
> - **Products Without Transactions:** No products without sales activity were detected during the analyzed period.
> - **Invoice Headers → Invoice Lines:** No invoice headers without corresponding line items were detected.
> - **Invoice Headers → Stores:** No orphan store references were detected; every `StoreID` in `Invoices_Header` exists in the Stores dataset.
> - **Invoice Lines → Invoice Headers:** No orphan invoice lines were detected; every `InvoiceID` in `Invoices_Lines` has a matching record in `Invoices_Header`.
> - **Invoice Lines → Products:** No orphan product references were detected; every `ProductID` in `Invoices_Lines` exists in the Products dataset.
> - **Overall Finding:** The tested relationships are structurally consistent, with no referential-integrity violations detected in the initial-load dataset.

[← Back to main README](../README.md)
