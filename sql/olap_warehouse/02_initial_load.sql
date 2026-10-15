-- Set Saturday as the starting day of the week
SET DATEFIRST 6;

DECLARE @SourceHighWatermark DATETIME2(3);

SET @SourceHighWatermark =
(
    SELECT MAX(LastModifiedAt)
    FROM lh_pos_retail.silver.invoices_header
);
-- Applying atomicity on the whole initial load
BEGIN TRY
    BEGIN TRANSACTION;
-- Generation for full calender of 2026 in dim_date
INSERT INTO retail.dim_date
(
    DateKey,
    FullDate,
    Year,
    MonthNumber,
    MonthName,
    DayOfMonth,
    DayOfWeek,
    DayName
)
SELECT
    CAST(FORMAT(d.date_value, 'yyyyMMdd') AS INT) AS DateKey,
    d.date_value AS FullDate,
    YEAR(d.date_value) AS year,
    MONTH(d.date_value) AS MonthNumber,
    DATENAME(MONTH, d.date_value) AS MonthName,
    DATEPART(day, d.date_value) AS DayOfMonth,
    DATEPART(WEEKDAY, d.date_value) AS DayOfWeek,
    DATENAME(weekday, d.date_value) AS DayName
FROM (
    SELECT DATEADD(DAY, value, '2026-01-01') AS date_value
    FROM GENERATE_SERIES(0, 364)
) d;
-- Insertion for silver.stores into retail.dim_store
INSERT INTO retail.dim_store
(
    StoreID,
    StoreName,
    Region,
    City
)
SELECT 
    StoreID,
    StoreName,
    Region,
    City
FROM lh_pos_retail.silver.stores;
-- Insertion for silver.products into retail.dim_product
INSERT INTO retail.dim_product
(
    ProductID,
    ProductName,
    Category
)
SELECT
    ProductID,
    ProductName,
    Category
FROM lh_pos_retail.silver.products;
-- Insertion for header and lines merged into retail.fact_daily_sales
INSERT INTO retail.fact_daily_sales
(
    DateKey,
    StoreKey,
    ProductKey,
    SalesAmount
)
SELECT
    CAST(FORMAT(ih.InvoiceDate, 'yyyyMMdd') AS INT) as DateKey,
    ds.StoreKey as StoreKey,
    dp.ProductKey as ProductKey,
    CAST(SUM(il.Quantity * il.UnitPrice) AS DECIMAL(18,2)) AS SalesAmount
FROM lh_pos_retail.silver.invoices_header as ih
INNER JOIN lh_pos_retail.silver.invoices_lines as il
ON ih.InvoiceID = il.InvoiceID
INNER JOIN retail.dim_product as dp
ON il.ProductID = dp.ProductID
INNER JOIN retail.dim_store as ds
ON ih.StoreID = ds.StoreID
WHERE ih.OrderStatus = 'Completed'
    AND ih.LastModifiedAt <= @SourceHighWatermark
GROUP BY
    CAST(FORMAT(ih.InvoiceDate, 'yyyyMMdd') AS INT),
    ds.StoreKey,
    dp.ProductKey;
-- Capturing the pipline watermark
INSERT INTO control.pipeline_state
(
    PipelineName,
    PipelineWatermark,
    UpdatedAt
)
VALUES
( 
    'silver_to_gold',
    @SourceHighWatermark,
    current_timestamp
 );
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;