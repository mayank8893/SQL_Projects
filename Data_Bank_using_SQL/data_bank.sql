-- 1) How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT(customer.node_id)) AS number_of_unique_nodes
FROM databank.dbo.customer_nodes AS customer





-- 2) What is the number of nodes per region?
SELECT r.region_id, r.region_name, COUNT(c.node_id) AS number_of_nodes
FROM databank.dbo.regions AS r JOIN databank.dbo.customer_nodes AS c ON r.region_id = c.region_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id





-- 3) How many customers are allocated to each region?
SELECT r.region_id, r.region_name, COUNT(DISTINCT(c.customer_id)) AS number_of_customers
FROM databank.dbo.regions AS r JOIN databank.dbo.customer_nodes AS c ON r.region_id = c.region_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id






-- 4) How many days on average are customers allocated to a different node?
WITH customerDates AS (
  SELECT 
    customer_id,
    node_id,
    MIN(start_date) AS first_date
  FROM customer_nodes
  GROUP BY customer_id,  node_id
),
reallocation AS (
  SELECT
    customer_id,
    node_id,
    first_date,
    DATEDIFF(DAY, first_date, 
             LEAD(first_date) OVER(PARTITION BY customer_id 
                                   ORDER BY first_date)) AS moving_days
  FROM customerDates
)

SELECT 
  ROUND(AVG(CAST(moving_days AS FLOAT)),2) AS avg_moving_days
FROM reallocation;





-- 5) What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH customerDates AS (
  SELECT 
    customer_id,
    region_id,
    node_id,
    MIN(start_date) AS first_date
  FROM customer_nodes
  GROUP BY customer_id, region_id, node_id
),
reallocation AS (
  SELECT
    customer_id,
    region_id,
    node_id,
    first_date,
    DATEDIFF(DAY, first_date, 
             LEAD(first_date) OVER(PARTITION BY customer_id 
                                   ORDER BY first_date)) AS moving_days
  FROM customerDates
)

SELECT 
  DISTINCT r.region_id,
  rg.region_name,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY r.moving_days) OVER(PARTITION BY r.region_id),2) AS median,
  ROUND(PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY r.moving_days) OVER(PARTITION BY r.region_id),2) AS percentile_80,
  ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY r.moving_days) OVER(PARTITION BY r.region_id),2) AS percentile_95
FROM reallocation r
JOIN regions rg ON r.region_id = rg.region_id
WHERE moving_days IS NOT NULL;





-- 6) What is the unique count and total amount for each transaction type?
SELECT trans.txn_type, COUNT(trans.customer_id) AS number_of_transactions, SUM(trans.txn_amount) AS transaction_amount
FROM databank.dbo.customer_transactions AS trans
GROUP BY trans.txn_type






-- 7) What is the total historical deposit counts and amounts for all customers?
WITH cte AS(
    SELECT trans.customer_id, trans.txn_type, COUNT(trans.customer_id) AS number_of_transactions, SUM(trans.txn_amount) AS transaction_amount
    FROM databank.dbo.customer_transactions AS trans
    WHERE trans.txn_type = 'deposit'
    GROUP BY trans.customer_id, trans.txn_type
)

SELECT AVG(number_of_transactions) AS avg_deposit_count, AVG(transaction_amount) AS avg_deposit_amount
FROM cte






-- 8) What is the total historical deposit counts and amounts for all customers?
WITH cte AS (
    SELECT trans.customer_id, MONTH(trans.txn_date) AS month, 
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawl
    FROM databank.dbo.customer_transactions AS trans
    GROUP BY customer_id, MONTH(trans.txn_date)
)

SELECT month, COUNT(customer_id) AS customer_count
FROM cte
WHERE deposit > 1 AND (purchase = 1 OR withdrawl = 1)
GROUP BY month








-- 9) What is the cloasing balance for each customer at the end of the month?
DECLARE @maxDate DATE;
SET @maxDate = (SELECT EOMONTH(MAX(txn_date)) FROM customer_transactions);

SELECT 
  customer_id,
  end_date,
  COALESCE(transactions, 0) AS transactions,
  SUM(COALESCE(transactions, 0)) OVER (PARTITION BY customer_id ORDER BY end_date) AS closing_balance
FROM (
  SELECT
    customer_id,
    EOMONTH(txn_date) AS end_date,
    SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount ELSE txn_amount END) AS transactions
  FROM customer_transactions
  GROUP BY customer_id, EOMONTH(txn_date)

  UNION ALL

  SELECT
    DISTINCT customer_id,
    EOMONTH(DATEADD(MONTH, 1, '2020-01-31')) AS end_date,
    NULL AS transactions
  FROM customer_transactions
  WHERE EOMONTH(DATEADD(MONTH, 1, '2020-01-31')) <= @maxDate
) AS combined_data;








-- 10) What is the percentage of customers who increase their closing balance by more than 5%?
-- Calculate the closing balance for each customer using the simplified query
WITH MonthlyBalances AS (
  SELECT
    customer_id,
    EOMONTH(txn_date) AS end_date,
    SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount ELSE txn_amount END) AS monthly_transactions
  FROM customer_transactions
  GROUP BY customer_id, EOMONTH(txn_date)
),
StartingBalances AS (
  SELECT 
    customer_id,
    end_date,
    MIN(monthly_transactions) AS starting_balance
  FROM MonthlyBalances
  GROUP BY customer_id, end_date
)
SELECT 
  COUNT(DISTINCT CASE WHEN closing_balance > 1.05 * starting_balance THEN customer_id END) AS customers_increased_balance,
  COUNT(DISTINCT customer_id) AS total_customers,
  100.0 * COUNT(DISTINCT CASE WHEN closing_balance > 1.05 * starting_balance THEN customer_id END) / COUNT(DISTINCT customer_id) AS percentage_increased_balance
FROM (
  SELECT
    sb.customer_id,
    sb.end_date,
    COALESCE(mb.monthly_transactions, 0) + sb.starting_balance AS closing_balance,
    sb.starting_balance
  FROM StartingBalances sb
  LEFT JOIN MonthlyBalances mb
  ON sb.customer_id = mb.customer_id AND sb.end_date = mb.end_date
) AS final_balances;









