-- =========================================================
-- FEBRUARY HEADER STATUS UPDATES
--
-- Applies the generated February status changes to existing
-- invoice headers and updates LastModifiedAt accordingly.
--
-- Before running this script:
--   Replace the dataset path in the BULK INSERT statement
--   with the actual local path of February_Header_Updates.csv.
-- =========================================================

-- Batch 1: Set current database context
USE Retail_DB;
GO

-- Batch 2: Create a text-based staging table for the update file
-- Staging keeps the raw CSV values as text before explicit type conversion.
CREATE TABLE dbo.February_Header_Updates_Staging (
    InvoiceID     VARCHAR(100),
    SourcePeriod  VARCHAR(20),
    OldStatus     VARCHAR(50),
    NewStatus     VARCHAR(50),
    ModifiedAt    VARCHAR(100)
);
GO

-- Batch 3: Bulk load the generated February status-change events into staging
BULK INSERT dbo.February_Header_Updates_Staging
FROM '{path}\February_Header_Updates.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
GO

-- Batch 4: Apply status changes to the matching invoice headers
-- OldStatus acts as a safeguard so an update is applied only when
-- the current source status matches the expected previous status.
-- LastModifiedAt records when the source transaction was changed.
UPDATE h
SET
    h.OrderStatus = u.NewStatus,
    h.LastModifiedAt = CAST(u.ModifiedAt AS DATETIME2)
FROM dbo.Invoices_Header AS h
JOIN dbo.February_Header_Updates_Staging AS u
    ON h.InvoiceID = CAST(u.InvoiceID AS UNIQUEIDENTIFIER)
WHERE h.OrderStatus = u.OldStatus;
GO

-- Batch 5: Remove the staging table after the updates are applied
DROP TABLE dbo.February_Header_Updates_Staging;
GO