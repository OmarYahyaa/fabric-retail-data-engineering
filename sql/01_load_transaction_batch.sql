-- =========================================================
-- TRANSACTION BATCH LOAD
--
-- Run this script once for each transaction batch.
-- Before each run:
--   1. Replace the dataset paths in the BULK INSERT statements.
--   2. Point them to the required batch (January, February, etc.).
--
-- Example execution order:
--   First run  -> January dataset
--   Second run -> February dataset
-- =========================================================

-- Batch 1: Set current database context
USE Retail_DB;
GO

-- Batch 2: Clear staging before loading a new batch
TRUNCATE TABLE dbo.Invoices_Lines_Staging;
GO

-- Batch 3: Bulk load clean header data directly from CSV into the target table
BULK INSERT dbo.Invoices_Header
FROM '{path}\Invoices_Header.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
GO

-- Batch 4: Bulk load raw line-item data into staging to prevent type conversion failures
BULK INSERT dbo.Invoices_Lines_Staging
FROM '{path}\Invoices_Lines.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
GO

-- Batch 5: Cast types and load from staging to target table
-- Quantity values are stored in the CSV as decimal-formatted text (e.g., '3.0').
-- Direct TRY_CAST from VARCHAR to INT returns NULL, so we first convert to FLOAT,
-- then convert the numeric FLOAT value to INT while preserving missing values as NULL.
INSERT INTO dbo.Invoices_Lines (LineID, InvoiceID, ProductID, Quantity, UnitPrice)
SELECT 
    CAST(LineID AS UNIQUEIDENTIFIER),
    CAST(InvoiceID AS UNIQUEIDENTIFIER),
    TRY_CAST(ProductID AS INT),
    TRY_CAST(TRY_CAST(Quantity AS FLOAT) AS INT) AS Quantity,
    TRY_CAST(UnitPrice AS DECIMAL(10,2))
FROM dbo.Invoices_Lines_Staging;
GO