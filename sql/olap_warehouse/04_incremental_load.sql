-- Making sure that inital_load is ran first
IF NOT EXISTS
(
    SELECT 1
    FROM control.pipeline_state
    WHERE PipelineName = 'silver_to_gold'
)
BEGIN
    THROW 50001, 'Initial load must run first.', 1;
END;

DECLARE @SourceHighWatermark DATETIME2(3);

SET @SourceHighWatermark =
(
    SELECT MAX(LastModifiedAt)
    FROM lh_pos_retail.silver.invoices_header
);

DECLARE @PipelineWatermark DATETIME2(3);

SET @PipelineWatermark =
(
    SELECT PipelineWatermark
    FROM control.pipeline_state
    WHERE PipelineName = 'silver_to_gold'
);

BEGIN TRY
    BEGIN TRANSACTION;
-- Applying incremental load logic to dim_store
MERGE INTO retail.dim_store AS target
USING lh_pos_retail.silver.stores AS source
ON target.StoreID = source.StoreID
WHEN MATCHED THEN
  UPDATE SET
    target.StoreName = source.StoreName,
    target.Region = source.Region,
    target.City = source.City
WHEN NOT MATCHED THEN
  INSERT (StoreID, StoreName, Region, City)
  VALUES (source.StoreID, source.StoreName, source.Region, source.City);
-- Applying incremental load logic to dim_product
MERGE INTO retail.dim_product AS target
USING lh_pos_retail.silver.products AS source
ON target.ProductID = source.ProductID
WHEN MATCHED THEN
  UPDATE SET
    target.ProductName = source.ProductName,
    target.Category = source.Category
WHEN NOT MATCHED THEN
  INSERT (ProductID, ProductName, Category)
  VALUES (source.ProductID, source.ProductName, source.Category);
-- Applying incremental load logic to fact_daily_sales
WITH silver_soruce AS(
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
        AND ih.LastModifiedAt > @PipelineWatermark
        AND ih.LastModifiedAt <= @SourceHighWatermark
    GROUP BY
        CAST(FORMAT(ih.InvoiceDate, 'yyyyMMdd') AS INT),
        ds.StoreKey,
        dp.ProductKey
)

MERGE INTO retail.fact_daily_sales AS target
USING silver_soruce AS source
ON target.DateKey = source.DateKey AND target.StoreKey = source.StoreKey AND target.ProductKey = source.ProductKey
WHEN MATCHED THEN
  UPDATE SET
    target.SalesAmount = (target.SalesAmount + source.SalesAmount)
WHEN NOT MATCHED THEN
  INSERT (DateKey, StoreKey, ProductKey, SalesAmount)
  VALUES (source.DateKey, source.StoreKey, source.ProductKey, source.SalesAmount);

  UPDATE control.pipeline_state
  SET PipelineWatermark = @SourceHighWatermark,
      UpdatedAt = CURRENT_TIMESTAMP
  WHERE PipelineName = 'silver_to_gold'

  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

