## Pizza Runner SQL Project

This project is from **Week 2** of **Danny Ma's 8-Week SQL Challenge**. The case study revolves around **Pizza Runner**, a startup by Danny who wanted to Uber-ize pizza delivery. He began by recruiting runners to deliver pizzas from his house (the Pizza Runner HQ), and hired developers to build a mobile ordering app.

📄 **See all SQL queries in** [`Pizza_Runner.sql`](Pizza_Runner.sql)

![Screenshot 2023-08-05 at 8 42 52 AM](https://github.com/mayank8893/SQL_Projects/assets/69361645/ece9e32e-c35d-4b93-8548-fe8c4ef1953d)

---

### ✅ Case Study Questions Answered:

1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?

11. How many runners signed up for each 1-week period (starting 2021-01-01)?
12. What was the average time in minutes it took each runner to arrive at HQ to pick up an order?
13. Is there a relationship between the number of pizzas and how long the order takes to prepare?
14. What was the average distance traveled for each customer?
15. What was the difference between the longest and shortest delivery times?
16. What was the average speed for each runner for each delivery, and are there any trends?
17. What is the successful delivery percentage for each runner?

18. What are the standard ingredients for each pizza?
19. What was the most commonly added extra?
20. What was the most common exclusion?
21. Generate a formatted order item for each `customer_orders` record, like:
    - `Meat Lovers`
    - `Meat Lovers - Exclude Beef`
    - `Meat Lovers - Extra Bacon`
    - `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`
22. Generate an alphabetically ordered, comma-separated ingredient list for each pizza order with `2x` prefix for duplicates (e.g. `Meat Lovers: 2xBacon, Beef, ..., Salami`)
23. What is the total quantity of each ingredient used in all delivered pizzas, sorted by most frequent?

24. If a Meat Lovers pizza costs $12 and Vegetarian $10 (no extra charges), how much total revenue has Pizza Runner made (excluding delivery fees)?
25. What if there's a $1 charge for any pizza extras (e.g. added cheese)?
26. Design a new `ratings` table to allow customers to rate their runners (1 to 5), and insert sample data for each successful order.
27. Join the newly created `ratings` table with existing tables to show:
    - customer_id  
    - order_id  
    - runner_id  
    - rating  
    - order_time  
    - pickup_time  
    - time between order and pickup  
    - delivery duration  
    - average speed  
    - total pizzas in order

28. If runners are paid $0.30/km, and pizza prices are fixed as above — how much profit does Pizza Runner make after deducting runner pay?

29. If a new "Supreme" pizza with all toppings is added, how would the existing data model handle it? Write an `INSERT` statement to demonstrate adding it to the menu.

---

This project highlights advanced SQL skills like **data wrangling, aggregations, case logic, window functions, string formatting**, and even **schema design** — all in the context of a real-world inspired food delivery platform.
