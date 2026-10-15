-- SHow all table constraint
SELECT *
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'retail'
  AND TABLE_NAME = 'fact_daily_sales';
-- Check on creation for identity columns
SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    c.name AS IdentityColumnName
FROM sys.identity_columns AS ic
JOIN sys.columns AS c
    ON ic.object_id = c.object_id
    AND ic.column_id = c.column_id
JOIN sys.tables AS t
    ON ic.object_id = t.object_id
JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name = 'retail'
ORDER BY t.name;