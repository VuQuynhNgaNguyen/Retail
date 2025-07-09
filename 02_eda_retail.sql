-- EDA **BigQuery**
-- Dataset: Retail Transactions
-- Purpose: Exploratory Data Analysis on cleaned retail data
-- Author: Vu Quynh Nga NGUYEN
-- Project: Retail Analysis
-- Notes: Organized by analysis area - Revenue, Customer, RFM segmentation

----------------------------------------------------------------------------------------------
-- REVENUE ANALYSIS
----------------------------------------------------------------------------------------------

-- 1. Total Sales and Orders by Country
-- Summary revenue and order count per country, descending by revenue
SELECT
  Country,
  ROUND(SUM(Revenue), 2) AS total_revenue,
  COUNT(DISTINCT InvoiceNo) AS total_orders
FROM `retails-454113.online_retails.retails`
GROUP BY Country
ORDER BY total_revenue DESC;


-- 2. Monthly Revenue and Order Trends
-- Total monthly revenue, order count, and percentage growth compared to previous month
SELECT
  Year,
  Month,
  ROUND(SUM(Revenue), 2) AS monthly_revenue,
  COUNT(DISTINCT InvoiceNo) AS total_orders,
  ROUND(
    100 * (SUM(Revenue) - LAG(SUM(Revenue)) OVER (ORDER BY Year, Month)) / 
    LAG(SUM(Revenue)) OVER (ORDER BY Year, Month), 2
  ) AS pct_revenue_increase_over_month
FROM `retails-454113.online_retails.retails`
GROUP BY Year, Month
ORDER BY Year, Month;


-- 3. Average Revenue by Weekday
-- Average transaction revenue grouped by day of the week, highest first
SELECT
  Weekday,
  ROUND(AVG(Revenue), 2) AS avg_revenue
FROM `retails-454113.online_retails.retails`
GROUP BY Weekday
ORDER BY avg_revenue DESC;


-- 4. Top 20 Best-Selling Products by Revenue
-- Products ranked by revenue and quantity sold
SELECT
  Description,
  SUM(Quantity) AS total_quantity_sold,
  ROUND(SUM(Revenue), 2) AS total_revenue
FROM `retails-454113.online_retails.retails`
GROUP BY Description
ORDER BY total_revenue DESC
LIMIT 20;


-- 5. Products with Very Low Sales
-- Least revenue generating products with positive quantity sold
SELECT
  Description,
  SUM(Quantity) AS total_quantity,
  ROUND(SUM(Revenue), 2) AS total_revenue,
  COUNT(DISTINCT InvoiceNo) AS order_count
FROM `retails-454113.online_retails.retails`
GROUP BY Description
HAVING total_quantity > 0
ORDER BY total_revenue ASC
LIMIT 20;


----------------------------------------------------------------------------------------------
-- CUSTOMER ANALYSIS
----------------------------------------------------------------------------------------------

-- 6. Top 20 Customers by Total Revenue
-- Highest spending customers and their total orders
SELECT
  CustomerID,
  ROUND(SUM(Revenue), 2) AS total_revenue,
  COUNT(DISTINCT InvoiceNo) AS total_orders
FROM `retails-454113.online_retails.retails`
WHERE CustomerID IS NOT NULL AND Revenue > 0
GROUP BY CustomerID
ORDER BY total_revenue DESC
LIMIT 20;


-- 7. Top 20 Customers by Purchase Frequency
-- Customers ranked by number of unique orders placed
SELECT
  CustomerID,
  COUNT(DISTINCT InvoiceNo) AS purchase_frequency
FROM `retails-454113.online_retails.retails`
WHERE CustomerID IS NOT NULL AND Revenue > 0
GROUP BY CustomerID
ORDER BY purchase_frequency DESC
LIMIT 20;


-- 8. Average Order Value (AOV) per Customer
-- Average spending per order for each customer
SELECT
  CustomerID,
  ROUND(SUM(Revenue), 2) AS total_spent,
  COUNT(DISTINCT InvoiceNo) AS total_orders,
  ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS avg_order_value
FROM `retails-454113.online_retails.retails`
WHERE CustomerID IS NOT NULL AND Revenue > 0
GROUP BY CustomerID
ORDER BY avg_order_value DESC;


-- 9. Customer Retention vs. Churn by Monthly Activity
-- Counts customers with purchases in only one month (churned) versus multiple months (retained)
WITH customer_month_activity AS (
  SELECT
    CustomerID,
    FORMAT_DATE('%Y-%m', InvoiceDate) AS purchase_month
  FROM `retails-454113.online_retails.retails`
  WHERE CustomerID IS NOT NULL AND Revenue > 0
  GROUP BY CustomerID, purchase_month
),
monthly_count AS (
  SELECT
    CustomerID,
    COUNT(DISTINCT purchase_month) AS active_months
  FROM customer_month_activity
  GROUP BY CustomerID
)
SELECT
  COUNTIF(active_months = 1) AS churned_customers,
  COUNTIF(active_months > 1) AS retained_customers,
  COUNT(*) AS total_customers
FROM monthly_count;


----------------------------------------------------------------------------------------------
-- RFM SEGMENTATION
----------------------------------------------------------------------------------------------

-- 10. Create RFM Segmentation View (Run once)
-- Scores customers on Recency, Frequency, Monetary and assigns segments
CREATE OR REPLACE VIEW `retails-454113.online_retails.rfm_segmented_view` AS
WITH customer_rfm AS (
  SELECT
    CustomerID,
    DATE(MAX(InvoiceDate)) AS last_purchase_date,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    ROUND(SUM(Revenue), 2) AS monetary
  FROM `retails-454113.online_retails.retails`
  WHERE CustomerID IS NOT NULL AND Revenue > 0
  GROUP BY CustomerID
),
recency_calc AS (
  SELECT *,
    DATE_DIFF(CURRENT_DATE(), last_purchase_date, DAY) AS recency
  FROM customer_rfm
),
rfm_scored AS (
  SELECT *,
    CASE 
      WHEN recency <= 30 THEN 3
      WHEN recency <= 90 THEN 2
      ELSE 1
    END AS r_score,

    CASE 
      WHEN frequency >= 10 THEN 3
      WHEN frequency >= 5 THEN 2
      ELSE 1
    END AS f_score,

    CASE 
      WHEN monetary >= 1000 THEN 3
      WHEN monetary >= 500 THEN 2
      ELSE 1
    END AS m_score
  FROM recency_calc
)
SELECT *,
  CONCAT(r_score, f_score, m_score) AS rfm_score,
  CASE
    WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN '💎 Champions'
    WHEN r_score = 3 AND f_score >= 2 THEN '🌟 Loyal Customers'
    WHEN r_score = 2 AND f_score = 3 THEN '🔥 Potential Loyalist'
    WHEN r_score = 1 AND f_score >= 2 THEN '😟 At Risk'
    WHEN r_score = 1 AND f_score = 1 THEN '💤 Lost'
    ELSE '💡 Others'
  END AS segment
FROM rfm_scored;


-- 11. Count of Customers per RFM Segment
-- Summary count of customers in each RFM segment
SELECT
  segment,
  COUNT(DISTINCT CustomerID) AS customer_count
FROM `retails-454113.online_retails.rfm_segmented_view`
GROUP BY segment
ORDER BY customer_count DESC;


-- 12. Optional: View All Customer RFM Scores
-- Detailed RFM scores for each customer, ordered by score descending
SELECT
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  rfm_score,
  segment
FROM `retails-454113.online_retails.rfm_segmented_view`
ORDER BY rfm_score DESC;


-- =========================
-- INVENTORY & SUPPLY CHAIN ANALYSIS
-- =========================

-- 1. Identify Products with Frequent Stockouts
-- Products with zero or negative quantity sales indicating possible stockout or returns
SELECT
  Description,
  COUNT(*) AS stockout_events,
  SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS negative_or_zero_qty_events
FROM `retails-454113.online_retails.retails`
GROUP BY Description
HAVING negative_or_zero_qty_events > 0
ORDER BY stockout_events DESC
LIMIT 20;


-- 2. Products Potentially Overstocked
-- Products with consistently low sales quantity over time (e.g., last 6 months before 2011-12-10)
WITH recent_sales AS (
  SELECT
    Description,
    EXTRACT(YEAR FROM InvoiceDate) AS Year,
    EXTRACT(MONTH FROM InvoiceDate) AS Month,
    SUM(Quantity) AS monthly_quantity_sold
  FROM `retails-454113.online_retails.retails`
  WHERE DATE(InvoiceDate) >= DATE_SUB(DATE('2011-12-10'), INTERVAL 6 MONTH)
  GROUP BY Description, Year, Month
),
avg_monthly_sales AS (
  SELECT
    Description,
    AVG(monthly_quantity_sold) AS avg_quantity_last_6_months
  FROM recent_sales
  GROUP BY Description
)
SELECT
  Description,
  ROUND(avg_quantity_last_6_months, 2) AS avg_monthly_quantity_sold
FROM avg_monthly_sales
WHERE avg_quantity_last_6_months < 5 -- threshold for low sales, adjust as needed
ORDER BY avg_monthly_quantity_sold ASC
LIMIT 20;


-- 3. Simple Demand Forecasting: Next Month's Demand Estimate (Moving Average)
-- Estimate next month's demand by average quantity sold over past 3 months per product
WITH last_3_months_sales AS (
  SELECT
    Description,
    FORMAT_DATE('%Y-%m', DATE(InvoiceDate)) AS year_month,
    SUM(Quantity) AS quantity_sold
  FROM `retails-454113.online_retails.retails`
  WHERE DATE(InvoiceDate) >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)
  GROUP BY Description, year_month
),
avg_quantity AS (
  SELECT
    Description,
    AVG(quantity_sold) AS avg_quantity_3_months
  FROM last_3_months_sales
  GROUP BY Description
)
SELECT
  Description,
  ROUND(avg_quantity_3_months, 2) AS forecast_next_month_quantity
FROM avg_quantity
ORDER BY forecast_next_month_quantity DESC
LIMIT 20;

----------------------------------------------------------------------------------------------
-- END OF EDA SCRIPT
----------------------------------------------------------------------------------------------
