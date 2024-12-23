-- COFFEE SHOP SALES SQL PROJECT - MS SQL QUERIES

-- Basic Level Queries:

-- 1)	Total DAILY SALES, TOTAL QUANTITY and TOTAL ORDERS.
SELECT 
    CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000, 1),'K') AS total_sales,
    CONCAT(ROUND(COUNT(transaction_id) / 1000, 1),'K') AS total_orders,
    CONCAT(ROUND(SUM(transaction_qty) / 1000, 1),'K') AS total_quantity_sold
FROM Transactions

-- Insight: This query helps to find the KPI of Sales, Quantity, Orders .


-- 2)	Retrieve the number of unique products sold per store.
SELECT store_id, 
       COUNT(DISTINCT product_id) AS unique_products_sold
FROM Transactions
GROUP BY store_id;

-- Insight: This query helps to understand the variety of products sold at each store.


-- 3)	Calculate total revenue per transaction.
SELECT transaction_id, 
       transaction_qty * unit_price AS transaction_revenue
FROM Transactions;

-- Insight: This provides revenue at a per-transaction level, useful for calculating averages or trends.


-- 4)	List transactions where the unit price is above the average price of all products.
SELECT *
FROM Transactions
WHERE unit_price > (SELECT AVG(unit_price) FROM Transactions);

-- Insight: Identifies transactions involving premium-priced products, useful for premium segment analysis.


-- 5)	Count the number of transactions per hour.
SELECT DATEPART(HOUR, transaction_time) AS hour, 
       COUNT(transaction_id) AS transactions_count
FROM Transactions
GROUP BY DATEPART(HOUR, transaction_time)
ORDER BY hour;
 
-- Insight: Helps identify hourly transaction patterns, indicating peak and off-peak times.


-- Intermediate Level Queries:

-- 1)	Calculate total and average sales for each product category by month.

SELECT DATEPART(YEAR, transaction_date) AS year,
       DATEPART(MONTH, transaction_date) AS month,
       product_category,
	   -- Count(product_category),
       SUM(transaction_qty * unit_price) AS total_sales,
       AVG(transaction_qty * unit_price) AS avg_sales
FROM Transactions
GROUP BY DATEPART(YEAR, transaction_date), DATEPART(MONTH, transaction_date), product_category
ORDER BY DATEPART(YEAR, transaction_date), DATEPART(MONTH, transaction_date), product_category;

-- Insight: Tracks monthly performance at a category level, helping to spot trends in product sales.


-- 2)	Identify the top 3 best-selling products within each category based on quantity.
SELECT Top 3 product_category, 
       product_id, 
       product_detail,
	   product_type,
       SUM(transaction_qty) AS total_quantity_sold
FROM Transactions
GROUP BY product_category
,product_id
, product_detail,product_type
ORDER BY total_quantity_sold DESC

-- Insight: Reveals the most popular products per category, which is useful for inventory and promotional planning.


-- 3)	Calculate revenue generated by each store location for a given quarter (e.g., Q1 of 2023).
SELECT store_location, 
       Round(SUM(transaction_qty * unit_price),1) AS total_revenue
FROM Transactions
-- WHERE transaction_date BETWEEN '2023-01-01' AND '2023-03-31'
WHERE Datepart(QUARTER,transaction_date) = 1
GROUP BY store_location
ORDER BY total_revenue DESC;
 
-- Insight: Provides a regional breakdown of revenue for specific timeframes, highlighting top-performing stores.

-- 4)	Rank all products by sales within each store.
SELECT store_id, 
       product_id, 
       product_detail,
       SUM(transaction_qty * unit_price) AS total_sales,
       RANK() OVER (PARTITION BY store_id ORDER BY SUM(transaction_qty * unit_price) DESC) AS product_rank
FROM Transactions
-- where store_id = 3
GROUP BY store_id, product_id, product_detail;

-- Insight: Ranks products in terms of sales within each store, showing which products perform best at a local level.


-- 5)	Get the percentage share of each product category in total sales.
SELECT product_category, 
       SUM(transaction_qty * unit_price) AS category_sales,
       ROUND((SUM(transaction_qty * unit_price) / (SELECT SUM(transaction_qty * unit_price) FROM Transactions) * 100), 2) AS sales_percentage
FROM Transactions
GROUP BY product_category
ORDER BY sales_percentage DESC;
 
-- Insight: Shows how much each product category contributes to total revenue.


-- Advanced Level Queries:

-- 1)	Determine each store’s peak sales hour.
WITH hourly_sales AS (
    SELECT store_id,
           DATEPART(HOUR,transaction_time) AS hour,
           SUM(transaction_qty * unit_price) AS sales
    FROM Transactions
    GROUP BY store_id, DATEPART(HOUR,transaction_time)
)
SELECT store_id, 
       hour, 
        Round(MAX(sales),2) AS peak_sales
FROM hourly_sales
GROUP BY store_id, hour
ORDER BY store_id, peak_sales desc;

-- Insight: Identifies peak sales hour for each store, which is valuable for staffing and promotional strategies.


-- 2)	Calculate the average time between transactions for each store.
WITH transaction_diffs AS (
    SELECT store_id,
           DATEDIFF(SECOND, LAG(transaction_time) OVER (PARTITION BY store_id ORDER BY transaction_time), transaction_time) AS time_diff
    FROM Transactions
)
SELECT store_id,
       AVG(time_diff) AS avg_time_between_transactions
FROM transaction_diffs
WHERE time_diff IS NOT NULL
      GROUP BY store_id;

-- Insight: Measures transaction frequency at each store, giving insight into customer traffic.


-- 3)	List stores with above-average sales performance for a specified period.
WITH avg_sales AS (
    SELECT AVG(transaction_qty * unit_price) AS average_sales
    FROM Transactions
    WHERE transaction_date BETWEEN '2023-04-01' AND '2023-06-30'
)
SELECT t.store_id, 
       t.store_location, 
       SUM(t.transaction_qty * t.unit_price) AS total_sales
FROM Transactions t
WHERE t.transaction_date BETWEEN '2023-04-01' AND '2023-06-30'
GROUP BY t.store_id, t.store_location
HAVING SUM(t.transaction_qty * t.unit_price) > (
    SELECT average_sales
    FROM avg_sales
);

-- Another way using CROSS JOIN:
WITH avg_sales AS (
    SELECT AVG(transaction_qty * unit_price) AS average_sales
    FROM Transactions
    WHERE transaction_date BETWEEN '2023-04-01' AND '2023-06-30'
)
SELECT t.store_id, 
       t.store_location, 
       SUM(t.transaction_qty * t.unit_price) AS total_sales
FROM Transactions t
CROSS JOIN avg_sales
WHERE t.transaction_date BETWEEN '2023-04-01' AND '2023-06-30'
GROUP BY t.store_id, t.store_location
HAVING SUM(t.transaction_qty * t.unit_price) > (
    SELECT average_sales
    FROM avg_sales
);

-- Insight: Highlights stores that are overperforming relative to the average sales.


-- 4)	Identify products that make up the top 20% of total sales.
WITH sales_data AS (
    SELECT product_id,
           product_detail,
           SUM(transaction_qty * unit_price) AS product_sales,
           NTILE(5) OVER (ORDER BY SUM(transaction_qty * unit_price) DESC) AS sales_quintile
    FROM Transactions
    GROUP BY product_id, product_detail
)
SELECT product_id, 
       product_detail, 
       product_sales
FROM sales_data
WHERE sales_quintile = 1;

-- Insight: Lists high-performing products by sales, focusing on those that contribute significantly to revenue.


-- 5)	Analyze month-over-month growth % for each product category.
SELECT product_category,
       DATEPART(YEAR, transaction_date) AS year,
       DATEPART(MONTH, transaction_date) AS month,
       SUM(transaction_qty * unit_price) AS monthly_sales,
       LAG(SUM(transaction_qty * unit_price)) OVER (PARTITION BY product_category ORDER BY DATEPART(YEAR, transaction_date), DATEPART(MONTH, transaction_date)) AS previous_month_sales,
 (FORMAT(
        (SUM(transaction_qty * unit_price) - LAG(SUM(transaction_qty * unit_price)) OVER (PARTITION BY product_category ORDER BY DATEPART(YEAR, transaction_date), DATEPART(MONTH, transaction_date))) 
        / NULLIF(LAG(SUM(transaction_qty * unit_price)) OVER (PARTITION BY product_category ORDER BY DATEPART(YEAR, transaction_date), DATEPART(MONTH, transaction_date)), 0) * 100, 
        'N2'
    ) + '%' ) AS month_over_month_growth
FROM Transactions
GROUP BY product_category, DATEPART(YEAR, transaction_date), DATEPART(MONTH, transaction_date)
ORDER BY product_category, year, month;

-- Insight: Measures growth trends for each category month-over-month, revealing patterns in product demand.


-- 6)	Find Products Performing Above Average in Specific Stores.
WITH ProductAvgRevenue AS (
    SELECT product_id,
           product_detail,
           Round(AVG(transaction_qty * unit_price),2) AS avg_product_revenue
    FROM Transactions
    GROUP BY product_id, product_detail
)
SELECT t.store_id,
       t.store_location,
       t.product_id,
       t.product_detail,
       Round(SUM(t.transaction_qty * t.unit_price),2) AS store_product_revenue,
       par.avg_product_revenue
FROM Transactions t
JOIN ProductAvgRevenue par ON t.product_id = par.product_id
GROUP BY t.store_id, t.store_location, t.product_id, t.product_detail, par.avg_product_revenue
HAVING Round(SUM(t.transaction_qty * t.unit_price),2) > par.avg_product_revenue
ORDER BY t.store_id, store_product_revenue DESC;

-- Insights: This query helps identify product strengths at the store level and can guide targeted inventory decisions or promotions.
 	

