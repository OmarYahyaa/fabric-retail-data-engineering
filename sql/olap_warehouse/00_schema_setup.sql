CREATE SCHEMA retail;
GO

CREATE SCHEMA control;
GO

CREATE TABLE retail.dim_date(
    DateKey INT  NOT NULL,
    FullDate DATE NOT NULL,
    Year SMALLINT NOT NULL,
    MonthNumber SMALLINT NOT NULL,
    MonthName VARCHAR(10) NOT NULL,
    DayOfMonth SMALLINT NOT NULL,
    DayOfWeek SMALLINT NOT NULL,
    DayName VARCHAR(15) NOT NULL
);

ALTER TABLE retail.dim_date
ADD CONSTRAINT PK_dim_date
PRIMARY KEY NONCLUSTERED (DateKey) NOT ENFORCED;

CREATE TABLE retail.dim_store(
    StoreKey BIGINT IDENTITY,
    StoreID INT NOT NULL,
    StoreName VARCHAR(100),
    Region VARCHAR(50),
    City VARCHAR(100)
);

ALTER TABLE retail.dim_store
ADD CONSTRAINT PK_dim_store
PRIMARY KEY NONCLUSTERED (StoreKey) NOT ENFORCED;

CREATE TABLE retail.dim_product(
    ProductKey BIGINT IDENTITY,
    ProductID  INT NOT NULL,
    ProductName VARCHAR(100),
    Category VARCHAR(50)
);

ALTER TABLE retail.dim_product
ADD CONSTRAINT PK_dim_product
PRIMARY KEY NONCLUSTERED (ProductKey) NOT ENFORCED;

CREATE TABLE retail.fact_daily_sales(
    DateKey INT  NOT NULL,
    StoreKey BIGINT NOT NULL,
    ProductKey BIGINT NOT NULL,
    SalesAmount DECIMAL(18,2) NOT NULL
);

ALTER TABLE retail.fact_daily_sales
ADD CONSTRAINT FK_fact_daily_sales_date
FOREIGN KEY (DateKey)
REFERENCES retail.dim_date (DateKey)
NOT ENFORCED;

ALTER TABLE retail.fact_daily_sales
ADD CONSTRAINT FK_fact_daily_sales_store
FOREIGN KEY (StoreKey)
REFERENCES retail.dim_store (StoreKey)
NOT ENFORCED;

ALTER TABLE retail.fact_daily_sales
ADD CONSTRAINT FK_fact_daily_sales_product
FOREIGN KEY (ProductKey)
REFERENCES retail.dim_product (ProductKey)
NOT ENFORCED;

ALTER TABLE retail.fact_daily_sales
ADD CONSTRAINT PK_fact_daily_sales
PRIMARY KEY NONCLUSTERED (DateKey, StoreKey, ProductKey) NOT ENFORCED;

CREATE TABLE control.pipeline_state(
    PipelineName VARCHAR(50),
    PipelineWatermark DATETIME2(3),
    UpdatedAt DATETIME2(3)
);
