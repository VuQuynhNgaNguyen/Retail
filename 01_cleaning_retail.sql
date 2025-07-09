-- CLEANING **BigQuery**
-- Dataset: Retail Transactions
-- Purpose: Clean and prepare data for analysis
-- Author: Vu Quynh Nga NGUYEN
-- Project: Retail Analysis
-- Notes: Queries are ordered by logic - remove invalids, standardize, check quality, enrich data
----------------------------------------------------------------------------------------------

-- Create copy from raw table --
CREATE OR REPLACE TABLE `retails-454113.online_retails.original_data` AS
SELECT *
FROM `retails-454113.online_retails.retails`;


CREATE OR REPLACE TABLE `retails-454113.online_retails.retails` AS
SELECT *
FROM `retails-454113.online_retails.original_data`;



-- 1. Remove invalid rows: UnitPrice = 0 (no revenue generated)
CREATE OR REPLACE TABLE `retails-454113.online_retails.retails` AS
SELECT *
FROM `retails-454113.online_retails.retails`
WHERE UnitPrice <> 0;

-- 2. Standardize text: trim & lowercase Description 
CREATE OR REPLACE TABLE `retails-454113.online_retails.retails` AS
SELECT
  index,
  InvoiceNo,
  StockCode,
  LOWER(TRIM(Description)) AS Description,
  Quantity,
  InvoiceDate,
  UnitPrice,
  CustomerID,
  Country
FROM `retails-454113.online_retails.retails`;

-- 3. Add derived fields: Revenue, Year, Month, Weekday
CREATE OR REPLACE TABLE `retails-454113.online_retails.retails` AS
SELECT
  *,
  Quantity * UnitPrice AS Revenue,
  EXTRACT(YEAR FROM InvoiceDate) AS Year,
  EXTRACT(MONTH FROM InvoiceDate) AS Month,
  FORMAT_TIMESTAMP('%A', InvoiceDate) AS Weekday
FROM `retails-454113.online_retails.retails`;

-- 4. Check for NULLs across all important columns
SELECT
  COUNTIF(InvoiceNo IS NULL)    AS null_invoiceno,
  COUNTIF(StockCode IS NULL)    AS null_stockcode,
  COUNTIF(Description IS NULL)  AS null_description,
  COUNTIF(Quantity IS NULL)     AS null_quantity,
  COUNTIF(InvoiceDate IS NULL)  AS null_invoicedate,
  COUNTIF(UnitPrice IS NULL)    AS null_unitprice,
  COUNTIF(CustomerID IS NULL)   AS null_customerid,
  COUNTIF(Country IS NULL)      AS null_country
FROM `retails-454113.online_retails.retails`;

-- 5. Count duplicates (full row)
SELECT COUNT(*) AS duplicate_count
FROM `retails-454113.online_retails.retails`
GROUP BY 
  index, InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 6. Revenue from transactions with missing CustomerID
SELECT 
  ROUND(SUM(Quantity * UnitPrice), 2) AS revenue_missing_customerid
FROM `retails-454113.online_retails.retails`
WHERE CustomerID IS NULL;

-- 7. Dataset overview (size, uniqueness, time range)
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT InvoiceNo) AS total_invoices,
  COUNT(DISTINCT StockCode) AS unique_products,
  COUNT(DISTINCT CustomerID) AS unique_customers,
  COUNT(DISTINCT Country) AS unique_countries,
  MIN(InvoiceDate) AS first_date,
  MAX(InvoiceDate) AS last_date
FROM `retails-454113.online_retails.retails`;

-- 8. Classify invoice types
SELECT
  CASE
    WHEN STARTS_WITH(InvoiceNo, 'C') THEN 'Cancelled'
    WHEN STARTS_WITH(InvoiceNo, 'A') THEN 'Adjusted'
    WHEN SAFE_CAST(InvoiceNo AS INT64) IS NOT NULL THEN 'Purchase'
    ELSE 'Other'
  END AS InvoiceType,
  COUNT(*) AS total_rows
FROM `retails-454113.online_retails.retails`
GROUP BY InvoiceType
ORDER BY total_rows DESC;

-- 9. Check logical issues: Quantity <= 0 but positive revenue
SELECT *
FROM `retails-454113.online_retails.retails`
WHERE Quantity <= 0 AND Quantity * UnitPrice > 0;

-- 10. Identify outliers using 1st and 99th percentiles
/*
WITH bounds AS (
  SELECT
    APPROX_QUANTILES(Quantity, 100)[OFFSET(1)] AS q1,
    APPROX_QUANTILES(Quantity, 100)[OFFSET(99)] AS q99,
    APPROX_QUANTILES(UnitPrice, 100)[OFFSET(1)] AS p1,
    APPROX_QUANTILES(UnitPrice, 100)[OFFSET(99)] AS p99
  FROM `retails-454113.online_retails.retails`
)
SELECT 
  r.*,
  CASE WHEN r.Quantity < b.q1 OR r.Quantity > b.q99 THEN TRUE ELSE FALSE END AS is_quantity_outlier,
  CASE WHEN r.UnitPrice < b.p1 OR r.UnitPrice > b.p99 THEN TRUE ELSE FALSE END AS is_price_outlier
FROM `retails-454113.online_retails.retails` r
CROSS JOIN bounds b
WHERE r.Quantity < b.q1 OR r.Quantity > b.q99 
   OR r.UnitPrice < b.p1 OR r.UnitPrice > b.p99;
*/

WITH bounds AS (
  SELECT
    APPROX_QUANTILES(Quantity, 100)[OFFSET(1)] AS q1,
    APPROX_QUANTILES(Quantity, 100)[OFFSET(99)] AS q99,
    APPROX_QUANTILES(UnitPrice, 100)[OFFSET(1)] AS p1,
    APPROX_QUANTILES(UnitPrice, 100)[OFFSET(99)] AS p99
  FROM `retails-454113.online_retails.retails`
),
flagged AS (
  SELECT 
    *,
    CASE WHEN Quantity < q1 OR Quantity > q99 THEN TRUE ELSE FALSE END AS is_quantity_outlier,
    CASE WHEN UnitPrice < p1 OR UnitPrice > p99 THEN TRUE ELSE FALSE END AS is_price_outlier
  FROM `retails-454113.online_retails.retails` r
  CROSS JOIN bounds
)

SELECT 
  is_quantity_outlier,
  is_price_outlier,
  COUNT(*) AS count_rows
FROM flagged
GROUP BY is_quantity_outlier, is_price_outlier
ORDER BY is_quantity_outlier DESC, is_price_outlier DESC;

----------------------------------------------------------------------------------------------
-- END OF DATA CLEANING SCRIPT
----------------------------------------------------------------------------------------------


