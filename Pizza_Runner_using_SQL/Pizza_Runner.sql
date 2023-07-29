-- cleaning the data first and removing null, na values and putting in proper units.
SELECT 
  order_id,
  customer_id,
  pizza_id,
  CASE 
  	WHEN exclusions IS NULL OR exclusions LIKE 'null' THEN ''
    	ELSE exclusions 
    	END AS exclusions,
  CASE 
  	WHEN extras IS NULL OR extras LIKE 'null' THEN ''
    	ELSE extras 
    	END AS extras,
  order_time
INTO #customer_orders_temp
FROM customer_orders;


SELECT 
  order_id,
  runner_id,
  CAST(
  	CASE WHEN pickup_time LIKE 'null' THEN NULL ELSE pickup_time END 
      AS DATETIME) AS pickup_time,
  CAST(
  	CASE WHEN distance LIKE 'null' THEN NULL
        WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
        ELSE distance END
    AS FLOAT) AS distance,
  CAST(
  	CASE WHEN duration LIKE 'null' THEN NULL
        WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
        WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
        WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
        ELSE duration END
    AS INT) AS duration,
  CASE WHEN cancellation IN ('null', 'NaN', '') THEN NULL 
      ELSE cancellation
      END AS cancellation
INTO #runner_order_temp
FROM runner_orders;





-- 1) How many pizzas were ordered?

SELECT COUNT(order_id) AS number_of_pizzas_ordered
FROM customer_orders




-- 2) How many unique orders were made?
SELECT COUNT(DISTINCT(order_id)) AS number_of_unique_orders
FROM customer_orders





-- 3) How many successful orders were delivered by each runner?
-- cleaning the data using temp table

SELECT runner_id,  COUNT(order_id) AS number_of_successful_deliveries
FROM #runner_order_temp
WHERE cancellation IS NULL
GROUP BY runner_id










-- 4) How many of each type of pizza was delivered?
SELECT p.pizza_id, p.pizza_name, COUNT(*) AS number_of_pizzas_delivered
FROM (#customer_orders_temp AS c JOIN pizza_names AS p on c.pizza_id = p.pizza_id) JOIN #runner_order_temp AS r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY p.pizza_id, p.pizza_name






-- 5) How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, (SELECT COUNT(*) FROM #customer_orders_temp WHERE customer_id = c.customer_id AND pizza_id = 1) AS MeatLovers, 
                    (SELECT COUNT(*) FROM #customer_orders_temp WHERE customer_id = c.customer_id AND pizza_id = 2) AS Vegetarian
FROM #customer_orders_temp AS c
GROUP BY customer_id





-- 6) What was the maximum number of pizzas delivered in a single order?
SELECT order_id, COUNT(pizza_id) AS number_of_pizzas
FROM #customer_orders_temp
GROUP BY order_id
HAVING COUNT(pizza_id) = 3





-- 7) For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id, 
      SUM(CASE WHEN exclusions != '' OR extras != '' THEN 1 ELSE 0 END) AS has_change,
      SUM(CASE WHEN exclusions = '' AND extras = '' THEN 1 ELSE 0 END) AS no_change
FROM #customer_orders_temp AS c JOIN #runner_order_temp AS r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY customer_id






-- 8) How many pizzas were delivered that had both exclusions and extras?
SELECT SUM(CASE WHEN exclusions != '' AND extras != '' THEN 1 ELSE 0 END) AS has_both_change
FROM #customer_orders_temp AS c JOIN #runner_order_temp AS r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL






-- 9) What was the total volume of pizzas ordered for each hour of the day?
SELECT DATEPART(HOUR, order_time) AS hour, COUNT(*) AS number_of_pizzas_ordered
FROM #customer_orders_temp
GROUP BY DATEPART(HOUR, order_time)





-- 10) What was the volume of orders for each day of the week?
SELECT DATEPART(DW, order_time) AS day, COUNT(*) AS number_of_pizzas_ordered
FROM #customer_orders_temp
GROUP BY DATEPART(DW, order_time)






-- 11) How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)?
SELECT DATEPART(week, registration_date) AS week_number, COUNT(runner_id) As number_of_runners_signed_up
FROM runners
GROUP BY DATEPART(week, registration_date)





-- 12) What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH cte AS(
SELECT r.runner_id,  
        CASE 
          WHEN c.order_time <= r.pickup_time THEN DATEDIFF(MINUTE, c.order_time, r.pickup_time)
          ELSE DATEDIFF(MINUTE, c.order_time, DATEADD(DAY,1,r.pickup_time))
          END AS duration
FROM #customer_orders_temp AS c JOIN #runner_order_temp AS r ON c.order_id = r.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY r.runner_id, c.order_time, r.pickup_time
)

SELECT runner_id, AVG(duration) AS avg_duration
FROM cte
GROUP BY runner_id






-- 13) Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH cte AS(
SELECT c.order_id, COUNT(c.pizza_id) AS number_of_pizzas, 
        CASE 
          WHEN c.order_time <= r.pickup_time THEN DATEDIFF(MINUTE, c.order_time, r.pickup_time)
          ELSE DATEDIFF(MINUTE, c.order_time, DATEADD(DAY,1,r.pickup_time))
          END AS duration
FROM #customer_orders_temp AS c JOIN #runner_order_temp AS r ON c.order_id = r.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY c.order_id, c.order_time, r.pickup_time
)

SELECT number_of_pizzas, AVG(duration) AS avg_time
FROM cte
GROUP BY number_of_pizzas






-- 14) What was the average distance travelled for each customer?
SELECT c.customer_id, ROUND(AVG(r.distance),2) AS avg_distance 
FROM #customer_orders_temp AS c JOIN #runner_order_temp AS r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.customer_id






-- 15) What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(r.duration) - MIN(r.duration) AS difference_bw_longest_and_shortest_delivery_times
FROM #runner_order_temp AS r
WHERE r.duration is not NULL






-- 16) What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT r.runner_id, c.order_id, COUNT(c.order_id) AS pizza_count, ROUND(r.distance/r.duration*60,2) AS speed
FROM #runner_order_temp AS r JOIN #customer_orders_temp AS c ON r.order_id = c.order_id
WHERE r.cancellation is NULL
GROUP BY r.runner_id, c.order_id, r.distance, r.duration





-- 17) What is the successfull delivery_percentage for each runner?
WITH cte AS(
SELECT r.runner_id, 
     SUM (CASE WHEN r.cancellation IS NULL THEN 1 ELSE 0 END) AS successful,
     SUM (CASE WHEN r.cancellation IS NOT NULL THEN 1 ELSE 0 END) AS not_successful
FROM #runner_order_temp AS r
GROUP BY r.runner_id)

SELECT 
    runner_id,
    100.0 * successful / (successful + not_successful) AS successful_percentage
FROM cte;






-- 18) What are the standard ingredients for each pizza?
SELECT p.pizza_id, p.pizza_name, s.topping_id, t.topping_name
FROM pizza_names AS p
JOIN (
    SELECT pizza_id, CAST(value AS INT) AS topping_id
    FROM pizza_recipes
    CROSS APPLY STRING_SPLIT(toppings, ',')
) AS s ON p.pizza_id = s.pizza_id
JOIN pizza_toppings AS t ON t.topping_id = s.topping_id
GROUP BY p.pizza_id, p.pizza_name, s.topping_id, t.topping_name





-- 19) What was the most commonly added extra?
WITH cte AS(
SELECT order_id, value AS extra
FROM customer_orders
CROSS APPLY STRING_SPLIT(extras, ',')
WHERE extras IS NOT NULL AND extras != 'null' and LEN(extras) !=0
)

SELECT extra, t.topping_name, COUNT(*) number_of_times_added
FROM cte JOIN pizza_toppings as t ON extra = topping_id
GROUP BY extra, t.topping_name






-- 20) What was the most common exclusion?
WITH cte AS(
SELECT order_id, value AS exclusion
FROM customer_orders
CROSS APPLY STRING_SPLIT(exclusions, ',')
WHERE exclusions IS NOT NULL AND exclusions != 'null' and LEN(exclusions) !=0
)

SELECT exclusion, t.topping_name, COUNT(*) number_of_times_excluded
FROM cte JOIN pizza_toppings as t ON exclusion = topping_id
GROUP BY exclusion, t.topping_name






-- 21) Generate an order item for each record in the customers_orders table in the format of one of the following:
  -- Meat Lovers
  -- Meat Lovers - Exclude Beef
  -- Meat Lovers - Extra Bacon
  -- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

SELECT 
  pr.pizza_id,
  TRIM(value) AS topping_id,
  pt.topping_name
INTO #toppingsBreak
FROM pizza_recipes pr
  CROSS APPLY STRING_SPLIT(toppings, ',') AS t
JOIN pizza_toppings pt
  ON TRIM(t.value) = pt.topping_id;


ALTER TABLE #customer_orders_temp
ADD record_id INT IDENTITY(1,1);


SELECT 
  c.record_id,
  TRIM(e.value) AS extra_id
INTO #extrasBreak 
FROM #customer_orders_temp c
  CROSS APPLY STRING_SPLIT(extras, ',') AS e;


SELECT 
  c.record_id,
  TRIM(e.value) AS exclusion_id
INTO #exclusionsBreak 
FROM #customer_orders_temp c
  CROSS APPLY STRING_SPLIT(exclusions, ',') AS e;




WITH cteExtras AS (
  SELECT 
    e.record_id,
    'Extra ' + STRING_AGG(t.topping_name, ', ') AS record_options
  FROM #extrasBreak e
  JOIN pizza_toppings t
    ON e.extra_id = t.topping_id
  GROUP BY e.record_id
), 
cteExclusions AS (
  SELECT 
    e.record_id,
    'Exclusion ' + STRING_AGG(t.topping_name, ', ') AS record_options
  FROM #exclusionsBreak e
  JOIN pizza_toppings t
    ON e.exclusion_id = t.topping_id
  GROUP BY e.record_id
), 
cteUnion AS (
  SELECT * FROM cteExtras
  UNION
  SELECT * FROM cteExclusions
)

SELECT 
  c.record_id,
  c.order_id,
  c.customer_id,
  c.pizza_id,
  c.order_time,
  CONCAT_WS(' - ', p.pizza_name, STRING_AGG(u.record_options, ' - ')) AS pizza_info
FROM #customer_orders_temp c
LEFT JOIN cteUnion u
  ON c.record_id = u.record_id
JOIN pizza_names p
  ON c.pizza_id = p.pizza_id
GROUP BY
  c.record_id, 
  c.order_id,
  c.customer_id,
  c.pizza_id,
  c.order_time,
  p.pizza_name
ORDER BY record_id;






-- 22) Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH ingredients AS (
  SELECT 
    c.*,
    p.pizza_name,

    -- Add '2x' in front of topping_names if their topping_id appear in the #extrasBreak table
    CASE WHEN t.topping_id IN (
          SELECT extra_id 
          FROM #extrasBreak e 
          WHERE e.record_id = c.record_id)
      THEN '2x' + t.topping_name
      ELSE t.topping_name
    END AS topping

  FROM #customer_orders_temp c
  JOIN #toppingsBreak t
    ON t.pizza_id = c.pizza_id
  JOIN pizza_names p
    ON p.pizza_id = c.pizza_id

  -- Exclude toppings if their topping_id appear in the #exclusionBreak table
  WHERE t.topping_id NOT IN (
      SELECT exclusion_id 
      FROM #exclusionsBreak e 
      WHERE c.record_id = e.record_id)
)

SELECT 
  record_id,
  order_id,
  customer_id,
  pizza_id,
  order_time,
  CONCAT(pizza_name + ': ', STRING_AGG(topping, ', ')) AS ingredients_list
FROM ingredients
GROUP BY 
  record_id, 
  record_id,
  order_id,
  customer_id,
  pizza_id,
  order_time,
  pizza_name
ORDER BY record_id;







-- 23) What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH ingredients AS (
  SELECT 
    c.*,
    p.pizza_name,

    -- Add '2x' in front of topping_names if their topping_id appear in the #extrasBreak table
    CASE WHEN t.topping_id IN (
          SELECT extra_id 
          FROM #extrasBreak e 
          WHERE e.record_id = c.record_id)
      THEN '2x' + t.topping_name
      ELSE t.topping_name
    END AS topping

  FROM #customer_orders_temp c
  JOIN #toppingsBreak t
    ON t.pizza_id = c.pizza_id
  JOIN pizza_names p
    ON p.pizza_id = c.pizza_id

  -- Exclude toppings if their topping_id appear in the #exclusionBreak table
  WHERE t.topping_id NOT IN (
      SELECT exclusion_id 
      FROM #exclusionsBreak e 
      WHERE c.record_id = e.record_id)
)

SELECT 
  record_id,
  order_id,
  customer_id,
  pizza_id,
  order_time,
  CONCAT(pizza_name + ': ', STRING_AGG(topping, ', ')) AS ingredients_list
FROM ingredients
GROUP BY 
  record_id, 
  record_id,
  order_id,
  customer_id,
  pizza_id,
  order_time,
  pizza_name
ORDER BY record_id;






--24) If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT r.runner_id,  
        SUM(CASE WHEN c.pizza_id = 1 THEN 12 ELSE 10 END) AS money
FROM #customer_orders_temp AS c JOIN #runner_order_temp AS r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY r.runner_id





-- 25) What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra.

DECLARE @basecost INT
SET @basecost = 138 	-- @basecost = result of the previous question

SELECT 
  @basecost + SUM(CASE WHEN p.topping_name = 'Cheese' THEN 2
		  ELSE 1 END) updated_money
FROM #extrasBreak e
JOIN pizza_toppings p
  ON e.extra_id = p.topping_id;





-- 26) The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset -
-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS ratings
CREATE TABLE ratings (
  order_id INT,
  rating INT);
INSERT INTO ratings (order_id, rating)
VALUES 
  (1,3),
  (2,5),
  (3,3),
  (4,1),
  (5,5),
  (7,3),
  (8,4),
  (10,3);

 SELECT *
 FROM ratings;







 -- 27) Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--customer_id, order_id, runner_id, rating, order_time, pickup_time, Time between order and pickup, Delivery duration, Average speed, Total number of pizzas.
SELECT 
  c.customer_id,
  c.order_id,
  r.runner_id,
  c.order_time,
  r.pickup_time,
  DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS mins_difference,
  r.duration,
  ROUND(AVG(r.distance/r.duration*60), 1) AS avg_speed,
  COUNT(c.order_id) AS pizza_count
FROM #customer_orders_temp c
JOIN #runner_order_temp r 
  ON r.order_id = c.order_id
GROUP BY 
  c.customer_id,
  c.order_id,
  r.runner_id,
  c.order_time,
  r.pickup_time, 
  r.duration;






  --28) If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - 
  --how much money does Pizza Runner have left over after these deliveries?

  DECLARE @basecost INT
SET @basecost = 138

SELECT 
  @basecost AS revenue,
  SUM(distance)*0.3 AS runner_paid,
  @basecost - SUM(distance)*0.3 AS money_left
FROM #runner_order_temp;





-- 29) If Danny wants to expand his range of pizzas - 
--how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

ALTER TABLE pizza_recipes
ALTER COLUMN toppings VARCHAR(50);

INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');