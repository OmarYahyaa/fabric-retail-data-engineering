-- Batch 1: Create the source OLTP database
CREATE DATABASE Retail_DB;
GO

-- Batch 2: Set current database context
USE Retail_DB;
GO

-- Batch 3: Create the Invoice Header table for high-level transaction metadata
CREATE TABLE dbo.Invoices_Header (
    InvoiceID UNIQUEIDENTIFIER PRIMARY KEY,
    StoreID INT NOT NULL,
    InvoiceDate DATETIME2 NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL,
    OrderStatus NVARCHAR(50) NOT NULL,
    LastModifiedAt DATETIME2 NOT NULL
);
GO

-- Batch 4: Create the Invoice Lines table with Foreign Key reference to headers
CREATE TABLE dbo.Invoices_Lines (
    LineID UNIQUEIDENTIFIER PRIMARY KEY,
    InvoiceID UNIQUEIDENTIFIER NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NULL, -- Intentional NULLs for downstream data-quality handling
    UnitPrice DECIMAL(10,2) NOT NULL,
    
    CONSTRAINT FK_Invoices_Lines_Header
        FOREIGN KEY (InvoiceID)
        REFERENCES dbo.Invoices_Header(InvoiceID)
);
GO

-- Batch 5: Create a staging table using VARCHAR for all columns.
-- WHY NOT DIRECT BULK INSERT LIKE INVOICES_HEADER?
-- Invoices_Lines contains intentional NULLs in the Quantity column (generated for Fabric data quality testing).
-- When exported to CSV, pandas represents these NULLs as empty text strings and numbers as float strings (e.g., '1.0').
-- Direct BULK INSERT into an INT column fails because SQL Server cannot implicitly cast these text formats to INT.
-- This staging table acts as a text-friendly landing zone so we can
-- safely convert the data types before loading the target table.
CREATE TABLE dbo.Invoices_Lines_Staging (
    LineID VARCHAR(100),
    InvoiceID VARCHAR(100),
    ProductID VARCHAR(100),
    Quantity VARCHAR(100),
    UnitPrice VARCHAR(100)
);
GO