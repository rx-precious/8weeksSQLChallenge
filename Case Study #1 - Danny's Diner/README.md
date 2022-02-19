![Image](https://8weeksqlchallenge.com/images/case-study-designs/1.png)

# **Problem Statement**
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

All data used for this analysis can be accessed [here](
https://github.com/rx-precious/SQL-projects/blob/6bd95f48e5ed24af4dfe62b547ddcc6f8d851526/Case%20Study%20%231%20-%20Danny's%20Diner/Dataset%20Notebook.sql) and Solution Notebook [here](https://github.com/rx-precious/SQL-projects/blob/6bd95f48e5ed24af4dfe62b547ddcc6f8d851526/Case%20Study%20%231%20-%20Danny's%20Diner/Solution%20Notebook.sql)

# Summary
As at the time of analysis and with the data given, Customer A spent the most among the 3 customers with total-spent of $76 in the diner. Each customer have visited the diner at least twice(days) within this duration and Customer B with the highest days visited of 6 days. Ramen was the favourite item on the menu.

# 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT customer_id, SUM(price) AS TotalSpent
FROM dannys_diner.sales a
JOIN dannys_diner.menu b on a.product_id = b.product_id
GROUP BY 1;
```

| customer_id | TotalSpent |
| ----------- |  --------- |
| A           |         76 |
| B           |         74 |
| C           |         36 |


### Answer:

- Customer A spent $76 in total.
- Customer B spent $74 in total.
- Customer C spent $36 in total.


# 2. How many days has each customer visited the restaurant?

```sql
SELECT customer_id, COUNT(DISTINCT order_date) AS NDaysVisited
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY 1;
```


| customer_id | NDaysVisited |
|-------------|--------------|
| A           |            4 |
| B           |            6 |
| C           |            2 |

### Answer:
Customer B uniquely visited the diner more than the other customers with a total days visited of 6 while Customer A and B visited 4 and 2 days respectively.

# 3. What was the first item from the menu purchased by each customer?
```SQL
WITH productRank AS(
	SELECT customer_id, product_id, order_date, DENSE_RANK() OVER (partition By customer_id
    ORDER BY order_date) AS productRank
    FROM dannys_diner.sales)
```
A common table Expression was created which creates a ranking system that partitions the 'sales' table by `customer_id` and order by `order_date`.

| customer_id | product_id | order_date | productRank |
|-------------|------------|------------|-------------|
| A           |          1 | 2021-01-01 |           1 |
| A           |          2 | 2021-01-01 |           1 |
| A           |          2 | 2021-01-07 |           2 |
| A           |          3 | 2021-01-10 |           3 |
| A           |          3 | 2021-01-11 |           4 |
| A           |          3 | 2021-01-11 |           4 |
| B           |          2 | 2021-01-01 |           1 |
| B           |          2 | 2021-01-02 |           2 |
| B           |          1 | 2021-01-04 |           3 |
| B           |          1 | 2021-01-11 |           4 |
| B           |          3 | 2021-01-16 |           5 |
| B           |          3 | 2021-02-01 |           6 |
| C           |          3 | 2021-01-01 |           1 |
| C           |          3 | 2021-01-01 |           1 |
| C           |          3 | 2021-01-07 |           2 |

```SQL
SELECT DISTINCT a.customer_id,  b.product_name
FROM productRank a
JOIN dannys_diner.menu b ON a.product_id = b.product_id AND a.productRank = 1;
```

| customer_id | product_name |
|-------------|--------------|
| A           | sushi        |
| A           | curry        |
| B           | curry        |
| C           | ramen        |

### Answer
- Customer A ordered Sushi and Curry on the same day as their first order.
- Customer B and C ordered Curry and Ramen respectively as their first order.

# 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
SELECT b.product_name, COUNT(*) AS NTimesPurchased
FROM dannys_diner.sales a
JOIN dannys_diner.menu b ON a.product_id = b.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
```


| product_name | NTimesPurchased |
|--------------|-----------------|
| ramen        |               8 |

### Answer
- Ramen was the most ordered item on the menu.

# 5. Which item was the most popular for each customer?

```sql
WITH mostItemsR AS (
	SELECT customer_id, product_id, COUNT(*) AS NTimesPurchased,
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS productRank
	FROM dannys_diner.sales
	GROUP BY 1 , 2)

SELECT customer_id, b.product_name, NTimesPurchased
FROM mostItemsR a
JOIN dannys_diner.menu b ON a.product_id = b.product_id AND a.productRank = 1
ORDER BY 1;
```

| customer_id | product_name | NTimesPurchased |
|-------------|--------------|-----------------|
| A           | ramen        |               3 |
| B           | sushi        |               2 |
| B           | curry        |               2 |
| B           | ramen        |               2 |
| C           | ramen        |               3 |

### Answer
- Ramen was the most popular with Customer A and C with Customer B liking all the items on the menu.

# 6. Which item was purchased first by the customer after they became a member?

```sql
WITH itemPurchasedRank AS (
	SELECT a.customer_id, product_id,
		DENSE_RANK() OVER(PARTITION BY a.customer_id ORDER BY order_date) AS ProductRank
	FROM dannys_diner.members a
	JOIN dannys_diner.sales b ON a.customer_id = b.customer_id
	WHERE order_date >= join_date)

SELECT a.customer_id, b.product_name
FROM itemPurchasedRank a
JOIN dannys_diner.menu b ON a.product_id = b.product_id AND a.productRank = 1
ORDER BY 1;
```

| customer_id | product_name |
|-------------|--------------|
| A           | curry        |
| B           | sushi        |

### Answer
- Customer A and B ordered Curry and Sushi as their first order after becoming a member assuming they registered before making the order for the day.

# 7. Which item was purchased just before the customer became a member?

```SQL
WITH itemPurchasedRank AS (
	SELECT a.customer_id, product_id,
		DENSE_RANK() OVER(PARTITION BY a.customer_id ORDER BY order_date DESC) ProductRank
	FROM dannys_diner.members a
	JOIN dannys_diner.sales b ON a.customer_id = b.customer_id
	WHERE order_date < join_date)

SELECT a.customer_id, b.product_name
FROM itemPurchasedRank a
JOIN dannys_diner.menu b ON a.product_ID = b.product_id AND productRank = 1
ORDER BY 1;
```

| customer_id | product_name |
|-------------|--------------|
| A           | sushi        |
| A           | curry        |
| B           | sushi        |

## Answer
- Customer A ordered two items on the menu while Customer B ordered Sushi in the visit prior to registration.



# 8. What is the total items and amount spent for each member before they became a member?

```SQL
SELECT a.customer_id, COUNT(DISTINCT a.product_id) AS totalItems, SUM(c.price)
	AS amtSpent
FROM dannys_diner.sales a
JOIN dannys_diner.members b ON a.customer_id = b.customer_id AND a.order_date
		< b.join_date
JOIN dannys_diner.menu c ON a.product_id = c.product_id
GROUP BY 1
ORDER BY 1;
```

| customer_id | totalItems | amtSpent |
|-------------|------------|----------|
| A           |          2 |       25 |
| B           |          2 |       40 |

### Answer
- Customer A and B ordered two items on the menu and spent $25 and $40 respectively before registering as a member.

# 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```SQL
WITH pointsTable AS (
SELECT a.customer_id, a.product_id,
	CASE
		WHEN a.product_id = 1 THEN SUM(c.price) * 10 * 2
		ELSE SUM(c.price) * 10
    END AS pointsEarned
FROM dannys_diner.sales a
JOIN dannys_diner.menu c ON a.product_id = c.product_id
GROUP BY 1,2)

SELECT customer_id, SUM(pointsEarned) AS totalPointsEarned
FROM pointsTable
GROUP BY 1
ORDER BY 1;
```

| customer_id | totalPointsEarned |
|-------------|-------------------|
| A           |               860 |
| B           |               940 |
| C           |               360 |

### Answer
- Each Customer would have earned 860, 940 and 360 points respectively.

# 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```SQL
WITH pointsTable AS(
	SELECT a.customer_id, join_date, order_date, a.product_id,
		CASE
			WHEN order_date BETWEEN b.join_date AND b.join_date + INTERVAL 6 day
				THEN c.price * 10 *2
			WHEN a.product_id = 1 THEN c.price * 10 * 2
			ELSE c.price * 10
		END AS pointsEarned
    FROM dannys_diner.sales a
    JOIN dannys_diner.members b ON a.customer_id = b.customer_id AND order_date <= '2021-01-31'
	JOIN dannys_diner.menu c ON a.product_id = c.product_id
    )

SELECT customer_id, SUM(pointsEarned) AS Points
FROM pointsTable
GROUP BY 1
ORDER BY 1;
```

| customer_id | Points |
|-------------|--------|
| A           |   1370 |
| B           |    820 |

### Answer
- For the month of January, Customer A and B earned 1370 and 820 points each while enjoying the 2x benefit available during the first week of registration.

# Bonus Questions

```SQL
WITH q1sol AS (
	SELECT a.customer_id, a.order_date, c.product_name, c.price,
		CASE
			WHEN order_date >= b.join_date THEN 'Y'
			ELSE 'N'
		END AS member
FROM dannys_diner.sales a
LEFT JOIN dannys_diner.members b ON a.customer_id = b.customer_id
JOIN dannys_diner.menu c ON a.product_id = c.product_id
ORDER BY 1,2,4 DESC)
```

| customer_id | order_date | product_name | price | member |
|-------------|------------|--------------|-------|--------|
| A           | 2021-01-01 | curry        |    15 | N      |
| A           | 2021-01-01 | sushi        |    10 | N      |
| A           | 2021-01-07 | curry        |    15 | Y      |
| A           | 2021-01-10 | ramen        |    12 | Y      |
| A           | 2021-01-11 | ramen        |    12 | Y      |
| A           | 2021-01-11 | ramen        |    12 | Y      |
| B           | 2021-01-01 | curry        |    15 | N      |
| B           | 2021-01-02 | curry        |    15 | N      |
| B           | 2021-01-04 | sushi        |    10 | N      |
| B           | 2021-01-11 | sushi        |    10 | Y      |
| B           | 2021-01-16 | ramen        |    12 | Y      |
| B           | 2021-02-01 | ramen        |    12 | Y      |
| C           | 2021-01-01 | ramen        |    12 | N      |
| C           | 2021-01-01 | ramen        |    12 | N      |
| C           | 2021-01-07 | ramen        |    12 | N      |


```SQL
SELECT *,
	CASE
		WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY a.customer_id, member
			ORDER BY order_date)
		ELSE NULL
    END AS ranking
FROM q1SOl;
```


| customer_id | order_date | product_name | price | member | ranking |
|-------------|------------|--------------|-------|--------|---------|
| A           | 2021-01-01 | curry        |    15 | N      |    NULL |
| A           | 2021-01-01 | sushi        |    10 | N      |    NULL |
| A           | 2021-01-07 | curry        |    15 | Y      |       1 |
| A           | 2021-01-10 | ramen        |    12 | Y      |       2 |
| A           | 2021-01-11 | ramen        |    12 | Y      |       3 |
| A           | 2021-01-11 | ramen        |    12 | Y      |       3 |
| B           | 2021-01-01 | curry        |    15 | N      |    NULL |
| B           | 2021-01-02 | curry        |    15 | N      |    NULL |
| B           | 2021-01-04 | sushi        |    10 | N      |    NULL |
| B           | 2021-01-11 | sushi        |    10 | Y      |       1 |
| B           | 2021-01-16 | ramen        |    12 | Y      |       2 |
| B           | 2021-02-01 | ramen        |    12 | Y      |       3 |
| C           | 2021-01-01 | ramen        |    12 | N      |    NULL |
| C           | 2021-01-01 | ramen        |    12 | N      |    NULL |
| C           | 2021-01-07 | ramen        |    12 | N      |    NULL |
