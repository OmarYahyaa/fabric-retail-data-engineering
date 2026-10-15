-- Check on date table
    -- Check the count of days in the generated table
SELECT COUNT(*) FROM retail.dim_date;
    -- Check data for minimum date 
SELECT * FROM retail.dim_date WHERE FullDate = (SELECT MIN(FullDate) FROM retail.dim_date);
     -- Check data for maximum date 
SELECT * FROM retail.dim_date WHERE FullDate = (SELECT MAX(FullDate) FROM retail.dim_date);
    -- Check for first saturday in the year
SELECT *
FROM retail.dim_date
WHERE FullDate = '2026-01-03';
-- Check on store table
SELECT 
    'count_of_stores' AS check_type,
    COUNT(*) AS result
FROM retail.dim_store

UNION ALL

SELECT 
    'count_of_stores_key',
    COUNT(DISTINCT StoreKey)
FROM retail.dim_store

UNION ALL

SELECT 
    'count_of_stores_ID',
    COUNT(DISTINCT StoreID)
FROM retail.dim_store
-- Check on product table
SELECT 
    'count_of_products' AS check_type,
    COUNT(*) AS result
FROM retail.dim_product

UNION ALL

SELECT 
    'count_of_stores_key',
    COUNT(DISTINCT ProductKey)
FROM retail.dim_product

UNION ALL

SELECT 
    'count_of_stores_ID',
    COUNT(DISTINCT ProductID)
FROM retail.dim_product
-- Check on fact_daily_sales
    -- Check on the total records in gold equals what in gold
SELECT 'Count for Gold fact rows' AS type, COUNT(*) AS result FROM retail.fact_daily_sales

UNION ALL

SELECT 'Count for Silver grain rows' ,COUNT(*)
FROM
(
    SELECT
        CAST(FORMAT(ih.InvoiceDate, 'yyyyMMdd') AS INT) AS DateKey,
        s.StoreID,
        p.ProductID
    FROM lh_pos_retail.silver.invoices_header AS ih
    INNER JOIN lh_pos_retail.silver.invoices_lines AS il
        ON ih.InvoiceID = il.InvoiceID
    INNER JOIN lh_pos_retail.silver.products AS p
        ON il.ProductID = p.ProductID
    INNER JOIN lh_pos_retail.silver.stores AS s
        ON ih.StoreID = s.StoreID
    WHERE ih.OrderStatus = 'Completed'
    GROUP BY
        CAST(FORMAT(ih.InvoiceDate, 'yyyyMMdd') AS INT),
        s.StoreID,
        p.ProductID
) AS t;
    -- Check on the SalesAmount that calculated in gold match what in silver
SELECT 'SalesAmount from gold' AS type, SUM(SalesAmount) AS result FROM retail.fact_daily_sales

UNION ALL

SELECT 'SalesAmount from silver', SUM(SalesAmount) FROM
(
SELECT
     CAST(SUM(il.Quantity * il.UnitPrice) AS DECIMAL(18,2)) AS SalesAmount
FROM lh_pos_retail.silver.invoices_header AS ih
INNER JOIN lh_pos_retail.silver.invoices_lines AS il
    ON ih.InvoiceID = il.InvoiceID
INNER JOIN lh_pos_retail.silver.products AS p
    ON il.ProductID = p.ProductID
INNER JOIN lh_pos_retail.silver.stores AS s
    ON ih.StoreID = s.StoreID
WHERE ih.OrderStatus = 'Completed'
GROUP BY
    CAST(FORMAT(ih.InvoiceDate, 'yyyyMMdd') AS INT),
    s.StoreID,
    p.ProductID
) AS t