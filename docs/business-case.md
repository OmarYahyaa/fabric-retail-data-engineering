[← Back to main README](../README.md)

# Business Case

## Business Context

A retail organization operates 200 stores that generate daily point-of-sale (POS) transactions.

The company needs timely operational visibility into transaction activity and reliable, curated sales information to support monitoring, reporting, and business decision-making.

Transactional sales data is maintained in a central SQL Server database, while Stores and Products master data are maintained separately by business teams.

## Business Needs

The solution should support two complementary analytical paths:

### 1. Near-Real-Time Operational Analytics

Provide timely visibility into recent transaction activity across all stores to support operational monitoring and short-term decision-making.

### 2. Curated Historical Analytics

Provide trusted, validated, and business-ready sales data for historical analysis by store, product, and date, as well as consistent BI reporting and audit requirements.

The overall solution should also support:

- Efficient processing as transaction volumes continue to grow.
- Controlled handling of data-quality issues without silently losing records.
- Traceability of historical data for audit and investigation.

## Transaction Lifecycle

Each sale consists of:

- An invoice header containing transaction-level information.
- One or more invoice lines containing the purchased products, quantities, and prices.

Invoices may change during their operational lifecycle.

An invoice can initially be:

- `Pending`

and later become:

- `Completed`
- `Cancelled`

Previously recorded invoices may therefore receive later status updates, while new transactions continue to arrive throughout the day.

For the scope of this project, invoice line items are considered immutable after creation, while invoice headers may change as the transaction progresses through its lifecycle.

## Master Data

The organization maintains two main master datasets:

- Stores
- Products

These datasets are relatively small compared with transactional sales data and are used to enrich sales transactions for analytical reporting.

Historical tracking of changes to Store and Product attributes is not required for the current business case.

## Data Quality

The analytical solution must prevent data-quality problems from silently affecting reporting.

Records that cannot be safely used for analysis should remain traceable for investigation rather than being silently discarded.

The specific quality rules implemented in the project will be based on:

- Observed data-profiling findings.
- Defined business rules.
- Demonstrated impact on downstream analytics.

## Analytical Outcome

The solution should support two complementary analytical needs:

### Near-Real-Time Operational Monitoring

The operational dashboard should provide timely visibility into current transaction activity across stores, including:

- Transaction volume and status (`Completed`, `Pending`, and `Cancelled`).
- Recent transaction trends over time.
- Store-level transaction and sales activity.
- Product-level sales activity.
- Identification of high- and low-performing stores and products for operational follow-up.

This path is intended for timely operational awareness rather than authoritative historical reporting.

### Curated Historical Analytics

The curated analytical solution should provide trusted, business-ready data that supports:

- Historical sales analysis by store.
- Historical sales analysis by product.
- Sales trends over time.
- Consistent BI reporting based on validated data.
- Historical and auditable reporting.

The solution should remain simple enough to maintain while being capable of handling increasing transaction volumes and future business requirements.

---

[← Back to main README](../README.md)
