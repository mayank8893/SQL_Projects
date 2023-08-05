-- 1) How many customers had foodie-fi ever had?
SELECT COUNT(DISTINCT(customer_id)) As number_of_customers
FROM foodie_fi.dbo.subscriptions




-- 2) What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT Month(start_date) as month, COUNT(DISTINCT(customer_id)) as number_of_customers
FROM subscriptions
WHERE plan_id = 0
GROUP BY Month(start_date)





-- 3) What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.
SELECT p.plan_name, COUNT(DISTINCT(s.customer_id)) as number_of_customers
FROM plans as p JOIN  subscriptions as s ON p.plan_id = s.plan_id
WHERE s.start_date >= '2021-01-01' 
GROUP BY p.plan_name




-- 4) What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(DISTINCT(customer_id))  AS churn_customers, COUNT(DISTINCT(customer_id))/10 AS percent_of_churned_customers
FROM subscriptions AS s JOIN plans as p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'churn'





-- 5) How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH nextPlan AS (
  SELECT 
    s.customer_id,
    s.start_date,
    p.plan_name,
    LEAD(p.plan_name) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
)

SELECT 
  COUNT(*) AS churn_after_trial,
  100*COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS pct
FROM nextPlan
WHERE plan_name = 'trial' 
  AND next_plan = 'churn';





-- 6) What is the number and percentage of customer plans after their initial free trial?
WITH nextPlan AS (
  SELECT 
    s.customer_id,
    s.start_date,
    p.plan_name,
    LEAD(p.plan_name) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
)

SELECT 
    next_plan,
  COUNT(*) AS customer_plan,
  CAST(100*COUNT(*) AS FLOAT)/ (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS pct
FROM nextPlan
WHERE plan_name = 'trial' 
  AND next_plan IS NOT NULL
GROUP BY next_plan





-- 7) What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH plansDate AS (
  SELECT 
    s.customer_id,
    s.start_date,
	p.plan_id,
    p.plan_name,
    LEAD(s.start_date) OVER(PARTITION BY s.customer_id ORDER BY s.start_date) AS next_date
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
)

SELECT 
  plan_id,
  plan_name,
  COUNT(*) AS customers,
  CAST(100*COUNT(*) AS FLOAT) 
      / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS conversion_rate
FROM plansDate
WHERE (next_date IS NOT NULL AND (start_date < '2020-12-31' AND next_date > '2020-12-31'))
  OR (next_date IS NULL AND start_date < '2020-12-31')
GROUP BY plan_id, plan_name
ORDER BY plan_id;





-- 8) How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT(s.customer_id)) as customer_count
FROM subscriptions AS s JOIN plans as p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'pro annual' AND s.start_date >= '2020-01-01' AND s.start_date <= '2020-12-31'



-- 9) How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH trialPlan AS (
  SELECT 
    s.customer_id,
    s.start_date AS trial_date
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE p.plan_name = 'trial'
),
annualPlan AS (
  SELECT 
    s.customer_id,
    s.start_date AS annual_date
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE p.plan_name = 'pro annual'
)

SELECT 
  AVG(CAST(DATEDIFF(d, trial_date, annual_date) AS FLOAT)) AS avg_days_to_annual
FROM trialPlan t
JOIN annualPlan a 
ON t.customer_id = a.customer_id;




-- 10) Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)?
WITH trialPlan AS (
  SELECT 
    s.customer_id,
    s.start_date AS trial_date
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE p.plan_name = 'trial'
),
annualPlan AS (
  SELECT 
    s.customer_id,
    s.start_date AS annual_date
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE p.plan_name = 'pro annual'
),
datesDiff AS (
  SELECT 
    t.customer_id,
    DATEDIFF(d, trial_date, annual_date) AS diff
  FROM trialPlan t
  JOIN annualPlan a ON t.customer_id = a.customer_id
),
daysRecursion AS (
  SELECT 
    0 AS start_period, 
    30 AS end_period
  UNION ALL
  SELECT 
    end_period + 1 AS start_period,
    end_period + 30 AS end_period
  FROM daysRecursion
  WHERE end_period < 360
)

SELECT 
  dr.start_period,
  dr.end_period,
  COUNT(*) AS customer_count
FROM daysRecursion dr
LEFT JOIN datesDiff dd 
  ON (dd.diff >= dr.start_period AND dd.diff <= dr.end_period)
GROUP BY dr.start_period, dr.end_period;







-- 11) How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH nextPlan AS (
  SELECT 
    s.customer_id,
    s.start_date,
    p.plan_name,
    LEAD(p.plan_name) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
)

SELECT COUNT(*) AS pro_to_basic_monthly
FROM nextPlan
WHERE plan_name = 'pro monthly'
  AND next_plan = 'basic monthly'
  AND YEAR(start_date) = 2020;






--12) The Foodie-Fi team wants to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
--      monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
--      upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
--      upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
--      once a customer churns they will no longer make payments

--Use a recursive CTE to increment rows for all monthly paid plans until customers changing the plan, except 'pro annual'
WITH dateRecursion AS (
  SELECT 
    s.customer_id,
    s.plan_id,
    p.plan_name,
    s.start_date AS payment_date,
    --column last_date: last day of the current plan
    CASE 
      --if a customer kept using the current plan, last_date = '2020-12-31'
      WHEN LEAD(s.start_date) OVER(PARTITION BY s.customer_id ORDER BY s.start_date) IS NULL THEN '2020-12-31'
      --if a customer changed the plan, last_date = (month difference between start_date and changing date) + start_date
      ELSE DATEADD(MONTH, 
		   DATEDIFF(MONTH, start_date, LEAD(s.start_date) OVER(PARTITION BY s.customer_id ORDER BY s.start_date)),
		   start_date) END AS last_date,
    p.price AS amount
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  --exclude trials because they didn't generate payments 
  WHERE p.plan_name NOT IN ('trial')
    AND YEAR(start_date) = 2020

  UNION ALL

  SELECT 
    customer_id,
    plan_id,
    plan_name,
    --increment payment_date by monthly
    DATEADD(MONTH, 1, payment_date) AS payment_date,
    last_date,
    amount
  FROM dateRecursion
  --stop incrementing when payment_date = last_date
  WHERE DATEADD(MONTH, 1, payment_date) <= last_date
    AND plan_name != 'pro annual'
)
--Create a new table [payments]
SELECT 
  customer_id,
  plan_id,
  plan_name,
  payment_date,
  amount,
  ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY payment_date) AS payment_order
INTO payments
FROM dateRecursion
--exclude churns
WHERE amount IS NOT NULL
ORDER BY customer_id
OPTION (MAXRECURSION 365);






-- 13) How would you calculate the rate of growth for Foodie-Fi?
WITH monthlyRevenue AS (
  SELECT 
    MONTH(payment_date) AS months,
    SUM(amount) AS revenue
  FROM payments
  GROUP BY MONTH(payment_date)
)

SELECT 
  months,
  revenue,
  (revenue-LAG(revenue) OVER(ORDER BY months))/revenue AS revenue_growth
FROM monthlyRevenue;