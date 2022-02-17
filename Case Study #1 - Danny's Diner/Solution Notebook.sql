-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS TotalSpent
FROM dannys_diner.sales a
JOIN dannys_diner.menu b on a.product_id = b.product_id
GROUP BY 1;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS NDaysVisited
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY 1;

-- 3. What was the first item from the menu purchased by each customer?
WITH productRank AS(
	SELECT customer_id, product_id, order_date, DENSE_RANK() OVER (partition By customer_id
    ORDER BY order_date) AS productRank
    FROM dannys_diner.sales)

SELECT DISTINCT a.customer_id,  b.product_name
FROM productRank a
JOIN dannys_diner.menu b ON a.product_id = b.product_id AND a.productRank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT b.product_name, COUNT(*) AS NTimesPurchased
FROM dannys_diner.sales a
JOIN dannys_diner.menu b ON a.product_id = b.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer?
WITH mostItemsR AS (
	SELECT customer_id, product_id, COUNT(*) AS NTimesPurchased,
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS productRank
	FROM dannys_diner.sales
	GROUP BY 1 , 2)

SELECT customer_id, b.product_name, NTimesPurchased
FROM mostItemsR a
JOIN dannys_diner.menu b ON a.product_id = b.product_id AND a.productRank = 1
ORDER BY 1;

-- 6. Which item was purchased first by the customer after they became a member?
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


-- 7. Which item was purchased just before the customer became a member?
WITH itemPurchasedRank AS (
	SELECT a.customer_id, product_id, 
		DENSE_RANK() OVER(PARTITION BY a.customer_id ORDER BY order_date DESC) ProductRank
	FROM dannys_diner.members a
	JOIN dannys_diner.sales b ON a.customer_id = b.customer_id
	WHERE order_date < join_date)

SELECT a.customer_id, b.product_name
FROM itemPurchasedRank a
JOIN dannys_diner.menu b ON a.product_ID = b.product_id AND productRank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT a.customer_id, COUNT(*) totalItems, SUM(c.price) AS amtSpent
FROM dannys_diner.sales a
JOIN dannys_diner.members b ON a.customer_id = b.customer_id AND a.order_date < b.join_date
JOIN dannys_diner.menu c ON a.product_id = c.product_id
GROUP BY 1
ORDER BY 1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH pointsTable AS (
SELECT a.customer_id, a.product_id, 
	CASE
		WHEN a.product_id = 1 THEN SUM(c.price) * 10 * 2
		ELSE SUM(c.price) * 10
    END AS pointsEarned
FROM dannys_diner.sales a
JOIN dannys_diner.menu c ON a.product_id = c.product_id
GROUP BY 1,2)

SELECT customer_id, SUM(pointsEarned) totalPointsEarned
FROM pointsTable
GROUP BY 1
ORDER BY 1;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

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
    
SELECT customer_id, SUM(pointsEarned) Points
FROM pointsTable
GROUP BY 1
ORDER BY 1;

-- Bonus Questions

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

SELECT *, 
	CASE 
		WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY a.customer_id, member ORDER BY order_date)
		ELSE NULL
    END AS ranking
FROM q1SOl;
