# Danny's Diner SQL Project

For this project, I worked with the well-known **Danny’s Diner** schema to practice writing SQL queries that mimic real-world business questions. The dataset consists of three tables:

- **sales**: contains `customer_id`, `order_date`, and `product_id`
- **menu**: includes `product_id`, `product_name`, and `price`
- **members**: holds `customer_id` and their `join_date`

![Screenshot 2023-08-05 at 8 45 15 AM](https://github.com/mayank8893/SQL_Projects/assets/69361645/f00a5c09-f402-4f21-925f-8565aecc5161)



Using **Google BigQuery**, I wrote SQL queries to answer several practical questions about customer behavior, sales, and loyalty programs. Here are the questions I explored:

### Questions Answered

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item purchased by each customer?
4. What is the most purchased item on the menu, and how many times was it purchased?
5. What is the most popular item for each customer?
6. What item did each customer purchase first *after* becoming a member?
7. What item did each customer purchase *just before* becoming a member?
8. What is the total amount spent and total number of items ordered by each customer *before* becoming a member?
9. If each $1 spent equals 10 points (with sushi earning double), how many points does each customer have?
10. During the first week after joining the loyalty program, customers earn 2x points on all items — how many points do customers A and B have by the end of January?

All SQL logic and results can be found in **`sql_week1.pdf`**.

---

### Summary

This was a great exercise in joining tables, filtering data based on timeframes, and applying conditional logic using SQL. It helped reinforce concepts like window functions, subqueries, and point-based reward calculations - all within the context of a real-life business scenario.




