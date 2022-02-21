-- Data Cleaning
USE pizza_runner;

SET SQL_SAFE_UPDATES = 0; -- To allow for update of the table.

UPDATE customer_orders
-- Remove the null values present in the extras and exclusion columns of the customer orders table.
SET extras = CASE
			WHEN extras REGEXP '[0-9]' THEN extras
			ELSE ' ' END,
	exclusions = CASE
			WHEN exclusions REGEXP '[0-9]' THEN exclusions
			ELSE ' ' END;

-- Convert the distance and duration columns datatype to Float and integer repectively for easy arithmetic manipulation
UPDATE runner_orders
SET distance = CAST((CASE
			WHEN distance REGEXP 'km$' THEN LEFT(distance, POSITION('km' IN distance)-1)
			WHEN distance REGEXP '[0-9]' THEN distance
			ELSE 0 END) AS FLOAT),
	duration = CAST((CASE
			WHEN duration REGEXP 'min' THEN LEFT(duration, POSITION('min' IN duration)-1)
			WHEN duration REGEXP '[0-9]' THEN duration
			ELSE 0 END) AS UNSIGNED),
	cancellation = CASE
			WHEN cancellation IS NULL OR cancellation REGEXP 'null' THEN ' '
			ELSE cancellation END;

SET SQL_SAFE_UPDATES = 1;



--    A. Pizza Metrics
-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS NPizzasOrdered
FROM pizza_runner.customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS nCustomerOrders
FROM pizza_runner.Customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(*)
FROM pizza_runner.runner_orders
WHERE distance > 0
GROUP BY 1;


-- 4. How many of each type of pizza was delivered?
SELECT c.pizza_name , COUNT(*) AS nDelivered
FROM pizza_runner.customer_orders a
JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND b.distance > 0
JOIN pizza_runner.pizza_names c ON a.pizza_id = c.pizza_id
GROUP BY 1;


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT a.customer_id, pizza_name, COUNT(*)
FROM pizza_runner.customer_orders a
JOIN pizza_runner.pizza_names b ON a.pizza_id = b.pizza_id
GROUP BY 1;


-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT order_id, COUNT(*) AS MaxOrder
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH pizzaChange AS (SELECT a.order_id, a.customer_id, CASE
	WHEN exclusions REGEXP '[0-9]' OR extras REGEXP '[0-9]' THEN 1
    ELSE 0 END AS changes,  CASE
	WHEN exclusions REGEXP '[0-9]' OR extras REGEXP '[0-9]' THEN 0
    ELSE 1 END AS NoChanges
FROM pizza_runner.customer_orders a
JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND b.distance > 0)

SELECT customer_id, SUM(changes) AS Changes, SUM(noChanges) AS NoChanges
FROM pizzaChange
GROUP BY 1;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) nPizzaDelivered
FROM pizza_runner.customer_orders a
JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND b.distance > 0
WHERE exclusions REGEXP '[0-9]' AND extras REGEXP '[0-9]';

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT hour(order_time) AS HourOfDay, COUNT(*) AS nPIZzaOrdered
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 1;

-- 10. What was the volume of orders for each day of the week?
SELECT dayname(order_time) AS DayofWeek, COUNT(*), order_time
FROM pizza_runner.customer_orders
GROUP BY 1;

-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT CASE
	WHEN (datediff(registration_date, '2021-01-01')+1)/7 <= 1 THEN 1
    WHEN (datediff(registration_date, '2021-01-01')+1)/7 <=2 THEN 2
    WHEN (datediff(registration_date, '2021-01-01')+1)/7 <= 3 THEN 3
    ELSE NULL END AS weekPeriod, COUNT(*) AS nRunners
FROM pizza_runner.runners
GROUP BY 1;
-- Might not be ideal if dataset is larger than this. trying to find a more generic solution

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH duration AS(
	SELECT runner_id,  timediff(CAST(b.pickup_time AS DATETIME), a.order_time) AS duration
	FROM pizza_runner.customer_orders a
	JOIN pizza_runner.runner_orders b on a.order_id =b.order_id AND b.duration > 0)

SELECT runner_id, CAST(AVG(duration) AS TIME) AS avgRunnerTime
FROM duration
GROUP BY 1 ;


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH nPizzaTable AS(
	SELECT a.order_id, COUNT(*) AS nPizza, timediff(CAST(b.pickup_time AS DATETIME), a.order_time) AS duration
	FROM pizza_runner.customer_orders a
	JOIN pizza_runner.runner_orders b on a.order_id =b.order_id AND b.duration > 0
	GROUP BY 1)
SELECT nPizza, CAST(AVG(duration) AS TIME)
FROM nPizzaTable
GROUP BY 1;

-- 4. What was the average distance travelled for each customer?
SELECT customer_id, CAST(AVG(distance) AS FLOAT)
FROM pizza_runner.runner_orders a
JOIN pizza_runner.customer_orders b ON a.order_id = b.order_id AND a.duration > 0
GROUP BY 1 ;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration) - MIN(duration) AS differenceDeliveryTime
FROM pizza_runner.runner_orders
WHERE duration > 0;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
	SELECT runner_id, order_id, ROUND(distance / (duration/60), 2) AS Speed
	FROM pizza_runner.runner_orders
    WHERE duration > 0
    ORDER BY 1;

-- 7. What is the successful delivery percentage for each runner?
WITH sDel AS (
	SELECT runner_id, COUNT(*) SuccessDel
	FROM pizza_runner.runner_orders
	WHERE distance > 0
	GROUP BY 1)

SELECT a.runner_id, ROUND((b.SuccessDel/COUNT(*))*100, 0) SucDeliveryPercentage
FROM pizza_runner.runner_orders a
JOIN sDel b ON a.runner_id = b.runner_id
GROUP BY 1;

-- C. Ingredient Optimisation
CREATE TABLE numbers (
  n INT PRIMARY KEY);

INSERT INTO numbers VALUES (1),(2),(3),(4),(5),(6),(7),(8);

-- 1. What are the standard ingredients for each pizza?
CREATE TEMPORARY TABLE Expizza_recipe AS (SELECT
  a.pizza_id,  SUBSTRING_INDEX(SUBSTRING_INDEX(a.toppings, ',', numbers.n), ', ', -1)  AS toppings
FROM numbers INNER JOIN pizza_runner.pizza_recipes a
  ON CHAR_LENGTH(a.toppings)
     -CHAR_LENGTH(REPLACE(a.toppings, ',', ''))>=numbers.n-1
ORDER BY
  a.pizza_id, n);

SELECT a.pizza_id, b.topping_name
FROM Expizza_recipe a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
ORDER BY 1;

-- 2. What was the most commonly added extra?
CREATE TEMPORARY TABLE ExtrasExpanded AS (SELECT
  a.order_id, pizza_id, SUBSTRING_INDEX(SUBSTRING_INDEX(a.extras, ',', numbers.n), ', ', -1)  AS toppings
FROM numbers INNER JOIN pizza_runner.customer_orders a
  ON CHAR_LENGTH(a.extras)
     -CHAR_LENGTH(REPLACE(a.extras, ',', ''))>=numbers.n-1
WHERE extras REGEXP '[0-9]'
ORDER BY
  a.order_id, n);

SELECT b.topping_name, COUNT(*) TimesAdded
FROM ExtrasExpanded a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
GROUP BY 1
LIMIT 1;

-- concat back
SELECT order_id, GROUP_CONCAT(toppings) extras, CONCAT('Extra - ',GROUP_CONCAT(topping_name SEPARATOR', ')) AS extrasExp
FROM ExtrasExpanded a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
GROUP BY 1;

SELECT REGEXP_LIKE(c.toppings, '.,')
FROM ExtrasExpanded a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
JOIN pizza_runner.pizza_recipes c ON a.pizza_id = c.pizza_id  ;


-- 3. What was the most common exclusion?
CREATE TEMPORARY TABLE ExclusionsExpanded  (SELECT
  a.order_id,  a.pizza_id, SUBSTRING_INDEX(SUBSTRING_INDEX(a.exclusions, ',', numbers.n), ', ', -1)  AS toppings
FROM numbers INNER JOIN pizza_runner.customer_orders a
  ON CHAR_LENGTH(a.exclusions)
     -CHAR_LENGTH(REPLACE(a.exclusions, ',', ''))>=numbers.n-1
WHERE exclusions REGEXP '[0-9]'
ORDER BY
  a.order_id, n);

SELECT b.topping_name, COUNT(*) TimesExcluded
FROM ExclusionsExpanded a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
GROUP BY 1
LIMIT 1;

-- concat back
SELECT order_id, GROUP_CONCAT(DISTINCT toppings) exclusions, CONCAT('Exclude - ',GROUP_CONCAT(DISTINCT topping_name SEPARATOR', ')) AS exclusionsExp
FROM ExclusionsExpanded a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
GROUP BY 1;


-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH excludeT AS (SELECT order_id, GROUP_CONCAT(DISTINCT toppings SEPARATOR', ') exclusions, CONCAT('Exclude ',GROUP_CONCAT(DISTINCT topping_name SEPARATOR', ')) AS exclusionsExp
FROM ExclusionsExpanded a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
GROUP BY 1),

extrasT AS (SELECT order_id, GROUP_CONCAT(toppings SEPARATOR', ') extras, CONCAT('Extra ',GROUP_CONCAT(topping_name SEPARATOR', ')) AS extrasExp
FROM ExtrasExpanded a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
GROUP BY 1)

SELECT a.order_id,
	CASE WHEN a.extras REGEXP '[0-9]' AND a.exclusions REGEXP '[0-9]' THEN CONCAT(d.pizza_name, ' - ', c.exclusionsExp, ' - ', b.extrasExp)
		WHEN a.extras REGEXP '[0-9]' THEN CONCAT(d.pizza_name, ' - ', b.extrasExp)
        WHEN a.exclusions REGEXP '[0-9]' THEN CONCAT(d.pizza_name, ' - ', c.exclusionsExp)
		ELSE d.pizza_name
	END AS OrderList
FROM pizza_runner.customer_Orders a
JOIN pizza_runner.pizza_names d ON a.pizza_id = d.pizza_id
LEFT JOIN extrasT b  on a.extras = b.extras AND a.order_id = b.order_id
LEFT JOIN excludeT c on a.exclusions = c.exclusions AND a.order_id = c.order_id;


-- 5.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WIP



-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WIP

-- D. Pricing and Ratings
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT
	SUM(CASE
		WHEN pizza_id = 1 THEN 12
        ELSE 10
	END) AS Revenue
FROM pizza_runner.customer_orders a
JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND distance > 0;

-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
WITH nExtrasSold AS (SELECT
  COUNT(SUBSTRING_INDEX(SUBSTRING_INDEX(a.extras, ',', numbers.n), ', ', -1)) *  1 AS ExtrasRevenue
FROM numbers INNER JOIN pizza_runner.customer_orders a
  ON CHAR_LENGTH(a.extras)
     -CHAR_LENGTH(REPLACE(a.extras, ',', ''))>=numbers.n-1
WHERE extras REGEXP '[0-9]'
ORDER BY
  a.order_id, n),

  pizzaRevenue AS (
	SELECT
		SUM(CASE
			WHEN pizza_id = 1 THEN 12
			ELSE 10
		END) AS Revenue
	FROM pizza_runner.customer_orders a
	JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND distance > 0)

SELECT b.Revenue + a.ExtrasRevenue AS TotalRevenue
FROM nExtrasSold a
JOIN pizzaRevenue b;


-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

CREATE TABLE ratings (
	rating_id INT,
    rating VARCHAR(25)
);

INSERT INTO ratings
	(rating_id, rating)
VALUES
	(1, 'Very Unsatisfied'),
    (2, 'Unsatisfied'),
    (3, 'Neutral'),
    (4, 'Satisfied'),
    (5, 'Very Satisfied');

ALTER TABLE runner_orders
ADD rating_id INT;

SELECT * FROM runner_orders
WHERE duration > 0;


SET SQL_SAFE_UPDATES = 0;
UPDATE runner_orders
SET rating_id = FLOOR(RAND()*(5-1+1))+1
	WHERE distance > 0;

SET SQL_SAFE_UPDATES = 1;


-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas

SELECT a.customer_id, a.order_id, b.runner_id, b.rating_id, a.order_time, b.pickup_time,
	CAST(timediff(b.pickup_time , a.order_time) AS TIME) AS timeDifference,
    b.duration,
    ROUND(b.distance / (b.duration/60), 2) AS Speed,
    COUNT(a.order_id) AS TotalNPizza
FROM pizza_runner.customer_orders a
JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND b.duration > 0
GROUP BY 1,2,3;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH transportCost AS
	(SELECT SUM(duration * 0.30) As TotalLogisticsCost
	FROM pizza_runner.runner_orders
    WHERE duration > 0),
pizzaRevenue AS (
	SELECT
		SUM(CASE
			WHEN pizza_id = 1 THEN 12
			ELSE 10
		END) AS Revenue
	FROM pizza_runner.customer_orders a
	JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND distance > 0)

SELECT Revenue - TotalLogisticsCost AS RevLessLogisticsCost
FROM transportCost a
JOIN pizzaRevenue;


-- E. Bonus Questions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

ALTER TABLE pizza_names;
INSERT INTO pizza_runner.pizza_names
VALUES (3, 'Supreme');

SELECT * FROM pizza_names
