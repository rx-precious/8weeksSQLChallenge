![Image](https://8weeksqlchallenge.com/images/case-study-designs/2.png)

# **Problem Statement**
Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

Because Danny had a few years of experience as a data scientist - he was very aware that data collection was going to be critical for his business’ growth.

He has prepared for us an entity relationship diagram of his database design but requires further assistance to clean his data and apply some basic calculations so he can better direct his runners and optimise Pizza Runner’s operations.

All data used for this analysis can be found [here](https://github.com/rx-precious/8weeksSQLChallenge/blob/decdb9cb7f5357bcf9565c5b3d53e3066011d593/Case%20Study%202%20-%20Pizza%20Runner/Dataset%20Notebook.sql) and solution notebook [here](https://github.com/rx-precious/8weeksSQLChallenge/blob/93a95af34e8125ebb52c555f1cceff85e61cf74f/Case%20Study%202%20-%20Pizza%20Runner/Solution%20Notebook.sql)

# Summary
- Pizza Runner in the range of the data provided have had 14 pizza orders with customers uniquely placing 10 orders of which only 8 was successfully delivered.
- Of the two types of pizza available for ordering at Pizza Runner, Meatlovers was ordered more than the Vegetarian pizza with most of these orders happening in the evening.
- A positive linear relationship was observed in the waiting time before pickup and the number of pizzas ordered.
- Bacon was the most added extras while Cheese was the most excluded ingriedient though this exclusion is only seen in orders by customer 103.

#    A. Pizza Metrics
### 1. How many pizzas were ordered?
```SQL
SELECT COUNT(*) AS NPizzasOrdered
FROM pizza_runner.customer_orders;
```

| NPizzasOrdered |
|----------------|
|             14 |

#### Answer
- A total of 14 pizza orders was placed by customers of Pizza Runner.

### 2. How many unique customer orders were made?
```SQL
SELECT COUNT(DISTINCT order_id) AS nCustomerOrders
FROM pizza_runner.Customer_orders;
```

| nCustomerOrders |
|-----------------|
|              10 |

#### Answer
- 10 unique orders were placed by customers.

### 3. How many successful orders were delivered by each runner?
```SQL
SELECT runner_id, COUNT(*) nDelivered
FROM pizza_runner.runner_orders
WHERE distance > 0
GROUP BY 1;
```

| runner_id | nDelivered |
|-----------|------------|
|         1 |          4 |
|         2 |          3 |
|         3 |          1 |

#### Answer
- A total of 4, 3 and 1 orders were successfully delivered by Runner 1, 2 and 3.

### 4. How many of each type of pizza was delivered?
```SQL
SELECT c.pizza_name , COUNT(*) AS nDelivered
FROM pizza_runner.customer_orders a
JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND b.distance > 0
JOIN pizza_runner.pizza_names c ON a.pizza_id = c.pizza_id
GROUP BY 1;
```

| pizza_name | nDelivered |
|------------|------------|
| Meatlovers |          9 |
| Vegetarian |          3 |

#### Answer
- 9 boxes of the Meatlovers pizza type was delivered.
- 3 boxes of thr Vegetarian pizza type was delivered.

### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```SQL
SELECT a.customer_id, b.pizza_name, COUNT(*) AS nPizza
FROM pizza_runner.customer_orders a
JOIN pizza_runner.pizza_names b ON a.pizza_id = b.pizza_id
GROUP BY 1,2
ORDER BY 1;
```
| customer_id | pizza_name | nPizza |
|-------------|------------|--------|
|         101 | Meatlovers |      2 |
|         101 | Vegetarian |      1 |
|         102 | Meatlovers |      2 |
|         102 | Vegetarian |      1 |
|         103 | Meatlovers |      3 |
|         103 | Vegetarian |      1 |
|         104 | Meatlovers |      3 |
|         105 | Vegetarian |      1 |


#### Answer
- Majority of the pizza type ordered was the Meatlovers pizza.

### 6. What was the maximum number of pizzas delivered in a single order?
```SQL
SELECT a.order_id,a.customer_id, COUNT(*) AS MaxOrder
FROM pizza_runner.customer_orders a
JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND b.duration > 0
GROUP BY 1
ORDER BY 3 DESC
LIMIT 1;
```
| order_id | customer_id | MaxOrder |
|----------|-------------|----------|
|        4 |         103 |        3 |

#### Answer
- The maximum number of pizza delivered in  a single order was 3 pizza by customer 103.

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```SQL
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
```

| customer_id | Changes | NoChanges |
|-------------|---------|-----------|
|         101 |       0 |         2 |
|         102 |       0 |         3 |
|         103 |       3 |         0 |
|         104 |       2 |         1 |
|         105 |       1 |         0 |

#### Answer
- For the 5 customers pf Pizza runner, Customer 104 was the only one with pizza orders with at least a change and no change while other customers had either a change or no change at all.

### 8. How many pizzas were delivered that had both exclusions and extras?
```SQL
SELECT COUNT(*) nPizzaDelivered
FROM pizza_runner.customer_orders a
JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND b.distance > 0
WHERE exclusions REGEXP '[0-9]' AND extras REGEXP '[0-9]';
```

| nPizzaDelivered |
|-----------------|
|               1 |

#### Answer
- Only 1 pizza had both exlusions and extras.

### 9. What was the total volume of pizzas ordered for each hour of the day?
```SQL
SELECT hour(order_time) AS HourOfDay, COUNT(*) AS nPIZzaOrdered
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 1;
```

| HourOfDay | nPIZzaOrdered |
|-----------|---------------|
|        11 |             1 |
|        13 |             3 |
|        18 |             3 |
|        19 |             1 |
|        21 |             3 |
|        23 |             3 |

#### Answer
- The evening seems to be when majority of the orders come in from 6:00pm to 11:00pm.

### 10. What was the volume of orders for each day of the week?
```SQL
SELECT dayname(order_time) AS DayofWeek, COUNT(*) AS COUNT
FROM pizza_runner.customer_orders
GROUP BY 1;
```

| DayofWeek | COUNT |
|-----------|-------|
| Wednesday |     5 |
| Thursday  |     3 |
| Saturday  |     5 |
| Friday    |     1 |

#### Answer
- Wednesday and Saturday are the busiest day of the week for Pizza Runner with 5 orders on these days.

# B. Runner and Customer Experience
###  1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01) corrected to 2020-01-01
```SQL
SELECT CASE
	WHEN (datediff(registration_date, '2020-01-01')+1)/7 <= 1 THEN 1
  WHEN (datediff(registration_date, '2020-01-01')+1)/7 <=2 THEN 2
  WHEN (datediff(registration_date, '2020-01-01')+1)/7 <= 3 THEN 3
  ELSE NULL END AS weekPeriod, COUNT(*) AS nRunners
FROM pizza_runner.runners
GROUP BY 1;
```
-- Might not be ideal if dataset is larger than this. trying to find a more generic solution

| weekPeriod | nRunners |
|------------|----------|
|          1 |        2 |
|          2 |        1 |
|          3 |        1 |

#### Answer
- Two runners registered in the first week period while the remaining 2 registered in week 2 and 3.

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```SQL
WITH duration AS(
	SELECT runner_id,  timediff(b.pickup_time , a.order_time) AS duration
	FROM pizza_runner.customer_orders a
	JOIN pizza_runner.runner_orders b on a.order_id =b.order_id AND b.duration > 0)

SELECT runner_id, CAST(AVG(duration) AS TIME) AS avgRunnerTime
FROM duration
GROUP BY 1 ;
```

| runner_id | avgRunnerTime |
|-----------|---------------|
|         1 | 00:15:54      |
|         2 | 00:23:59      |
|         3 | 00:10:28      |

-- Runner 1, 2 and 3 spends approximately an average of 16, 24 and 10 minutes respectively to arrive at the pizza HQ to pickup the order


### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```SQL
WITH nPizzaTable AS(
	SELECT a.order_id, COUNT(*) AS nPizza,
    timediff(b.pickup_time, a.order_time) AS duration
	FROM pizza_runner.customer_orders a
	JOIN pizza_runner.runner_orders b on a.order_id =b.order_id AND b.duration > 0
	GROUP BY 1)

SELECT nPizza, CAST(AVG(duration) AS TIME) timeDifference
FROM nPizzaTable
GROUP BY 1;
```

| nPizza | timeDifference |
|--------|----------------|
|      1 | 00:12:21       |
|      2 | 00:18:23       |
|      3 | 00:29:17       |

- There seem to be a postive linear relationship between the number of pizza ordered and the amount of time it takes to prepare them.

### 4. What was the average distance travelled for each customer?
```SQL
SELECT customer_id, ROUND(AVG(distance), 2) AS avgDistance
FROM pizza_runner.runner_orders a
JOIN pizza_runner.customer_orders b ON a.order_id = b.order_id AND a.duration > 0
GROUP BY 1 ;
```

| customer_id | avgDistance |
|-------------|-------------|
|         101 |          20 |
|         102 |       16.73 |
|         103 |        23.4 |
|         104 |          10 |
|         105 |          25 |

### 5. What was the difference between the longest and shortest delivery times for all orders?

```SQL
SELECT MAX(duration) - MIN(duration) AS differenceDeliveryTime
FROM pizza_runner.runner_orders
WHERE duration > 0;
```

| differenceDeliveryTime |
|------------------------|
|                     30 |

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```SQL
SELECT runner_id, order_id, ROUND(distance / (duration/60), 2) AS Speed
FROM pizza_runner.runner_orders
WHERE duration > 0
ORDER BY 1;
```
| runner_id | order_id | Speed |
|-----------|----------|-------|
|         1 |        1 |  37.5 |
|         1 |        2 | 44.44 |
|         1 |        3 |  40.2 |
|         1 |       10 |    60 |
|         2 |        4 |  35.1 |
|         2 |        7 |    60 |
|         2 |        8 |  93.6 |
|         3 |        5 |    40 |
-- The speed varies between 35.1Km/h to 60Km/h for each runner except for `order_id` 8 delivered by Runner 2 with speed at 93.6km/hr. There is a need to look into why the runner delivered at that speed.


### 7. What is the successful delivery percentage for each runner?

```SQL
WITH sDel AS (
	SELECT runner_id, COUNT(*) SuccessDel
	FROM pizza_runner.runner_orders
	WHERE distance > 0
	GROUP BY 1)

SELECT a.runner_id, ROUND((b.SuccessDel/COUNT(*))*100, 0) SucDeliveryPercentage
FROM pizza_runner.runner_orders a
JOIN sDel b ON a.runner_id = b.runner_id
GROUP BY 1;
```
| runner_id | SucDeliveryPercentage |
|-----------|-----------------------|
|         1 |                   100 |
|         2 |                    75 |
|         3 |                    50 |


# C. Ingredient Optimisation
```SQL
CREATE TABLE numbers (
  n INT PRIMARY KEY);

INSERT INTO numbers VALUES (1),(2),(3),(4),(5),(6),(7),(8);
```

### 1. What are the standard ingredients for each pizza?
- The MySQL engine does not have a function to split values to multiple rows thus the need to use this approach to solit. More information about it can be found here [here](https://stackoverflow.com/questions/17942508/sql-split-values-to-multiple-rows)

```SQL
CREATE TEMPORARY TABLE Expizza_recipe AS (SELECT
  a.pizza_id,  SUBSTRING_INDEX(SUBSTRING_INDEX(a.toppings, ',', numbers.n), ', ', -1)  AS toppings
FROM numbers INNER JOIN pizza_runner.pizza_recipes a
  ON CHAR_LENGTH(a.toppings)
     -CHAR_LENGTH(REPLACE(a.toppings, ',', ''))>=numbers.n-1
ORDER BY
  a.pizza_id, n);

SELECT c.pizza_name, b.topping_name
FROM Expizza_recipe a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
JOIN pizza_runner.pizza_names c ON a.pizza_id = c.pizza_id
ORDER BY 1;
```

| pizza_name | topping_name |
|------------|--------------|
| Meatlovers | Bacon        |
| Meatlovers | BBQ Sauce    |
| Meatlovers | Beef         |
| Meatlovers | Cheese       |
| Meatlovers | Chicken      |
| Meatlovers | Mushrooms    |
| Meatlovers | Pepperoni    |
| Meatlovers | Salami       |
| Vegetarian | Cheese       |
| Vegetarian | Mushrooms    |
| Vegetarian | Onions       |
| Vegetarian | Peppers      |
| Vegetarian | Tomatoes     |
| Vegetarian | Tomato Sauce |

### 2. What was the most commonly added extra?

```SQL
CREATE TEMPORARY TABLE ExtrasExpanded AS (SELECT
  a.order_id, pizza_id, SUBSTRING_INDEX(SUBSTRING_INDEX(a.extras, ',', numbers.n), ', ', -1)  AS toppings
FROM numbers INNER JOIN pizza_runner.customer_orders a
  ON CHAR_LENGTH(a.extras)
     -CHAR_LENGTH(REPLACE(a.extras, ',', ''))>=numbers.n-1
WHERE extras REGEXP '[0-9]'
ORDER BY a.order_id, n);

SELECT b.topping_name, COUNT(*) TimesAdded
FROM ExtrasExpanded a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
GROUP BY 1
LIMIT 1;
```

| topping_name | TimesAdded |
|--------------|------------|
| Bacon        |          4 |

#### Answer
- Bacon is the most requested extras.

### 3. What was the most common exclusion?
```SQL
CREATE TEMPORARY TABLE ExclusionsExpanded  (SELECT
  a.order_id,  a.pizza_id, SUBSTRING_INDEX(SUBSTRING_INDEX(a.exclusions, ',', numbers.n), ', ', -1)  AS toppings
FROM numbers INNER JOIN pizza_runner.customer_orders a
  ON CHAR_LENGTH(a.exclusions)
     -CHAR_LENGTH(REPLACE(a.exclusions, ',', ''))>=numbers.n-1
WHERE exclusions REGEXP '[0-9]'
ORDER BY a.order_id, n);


SELECT b.topping_name, COUNT(*) TimesExcluded
FROM ExclusionsExpanded a
JOIN pizza_runner.pizza_toppings b ON a.toppings = b.topping_id
GROUP BY 1
LIMIT 1;
```

| topping_name | TimesExcluded |
|--------------|---------------|
| Cheese       |             4 |

#### answer
- Cheese is the most commonly excluded ingredient in pizza ordered by customers.


### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

```SQL
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
```
| order_id | OrderList                                                       |
|----------|-----------------------------------------------------------------|
|        1 | Meatlovers                                                      |
|        2 | Meatlovers                                                      |
|        3 | Meatlovers                                                      |
|        3 | Vegetarian                                                      |
|        4 | Meatlovers - Exclude Cheese                                     |
|        4 | Meatlovers - Exclude Cheese                                     |
|        4 | Vegetarian - Exclude Cheese                                     |
|        5 | Meatlovers - Extra Bacon                                        |
|        6 | Vegetarian                                                      |
|        7 | Vegetarian - Extra Bacon                                        |
|        8 | Meatlovers                                                      |
|        9 | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              |
|       10 | Meatlovers                                                      |
|       10 | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |

### 5.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
#### WIP



### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
##### WIP

# D. Pricing and Ratings
### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

```SQL
SELECT
	SUM(CASE
		WHEN pizza_id = 1 THEN 12
        ELSE 10
	END) AS Revenue
FROM pizza_runner.customer_orders a
JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND distance > 0;
```
| Revenue |
|---------|
|     138 |

#### Answer
- Total Revenue made from the delivered pizza excluding extras wass $138

### 2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra

```SQL
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
```
| TotalRevenue |
|--------------|
|          144 |

#### Answer
- Total Revenue made by Pizza Runner on Pizza and extras delivered was $144

### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

```SQL
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
```
- Ratings were randomly assigned to all successful deliveries

```SQL
ALTER TABLE runner_orders
ADD rating_id INT;

UPDATE runner_orders
SET rating_id = FLOOR(RAND()*(5-1+1))+1
	WHERE distance > 0;
```


### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas
```SQL
SELECT a.customer_id, a.order_id, b.runner_id, b.rating_id, a.order_time, b.pickup_time,
	CAST(timediff(b.pickup_time , a.order_time) AS TIME) AS timeDifference,
    b.duration,
    ROUND(b.distance / (b.duration/60), 2) AS Speed,
    COUNT(a.order_id) AS TotalNPizza
FROM pizza_runner.customer_orders a
JOIN pizza_runner.runner_orders b ON a.order_id = b.order_id AND b.duration > 0
GROUP BY 1,2,3;
```
| customer_id | order_id | runner_id | rating_id | order_time          | pickup_time         | timeDifference | duration | Speed | TotalNPizza |
|-------------|----------|-----------|-----------|---------------------|---------------------|----------------|----------|-------|-------------|
|         101 |        1 |         1 |         5 | 2020-01-01 18:05:02 | 2020-01-01 18:15:34 | 00:10:32       | 32       |  37.5 |           1 |
|         101 |        2 |         1 |         4 | 2020-01-01 19:00:52 | 2020-01-01 19:10:54 | 00:10:02       | 27       | 44.44 |           1 |
|         102 |        3 |         1 |         3 | 2020-01-02 23:51:23 | 2020-01-03 00:12:37 | 00:21:14       | 20       |  40.2 |           2 |
|         103 |        4 |         2 |         1 | 2020-01-04 13:23:46 | 2020-01-04 13:53:03 | 00:29:17       | 40       |  35.1 |           3 |
|         104 |        5 |         3 |         2 | 2020-01-08 21:00:29 | 2020-01-08 21:10:57 | 00:10:28       | 15       |    40 |           1 |
|         105 |        7 |         2 |         5 | 2020-01-08 21:20:29 | 2020-01-08 21:30:45 | 00:10:16       | 25       |    60 |           1 |
|         102 |        8 |         2 |         1 | 2020-01-09 23:54:33 | 2020-01-10 00:15:02 | 00:20:29       | 15       |  93.6 |           1 |
|         104 |       10 |         1 |         5 | 2020-01-11 18:34:49 | 2020-01-11 18:50:20 | 00:15:31       | 10       |    60 |           2 |

### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

```SQL
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
```

| RevLessLogisticsCost |
|----------------------|
|                 82.8 |

#### Answer
- Pizza Runner after successful deliveries of pizza orderd have $82.80 left.

# E. Bonus Questions
### If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

```SQL
ALTER TABLE pizza_names;
INSERT INTO pizza_runner.pizza_names
VALUES (3, 'Supreme');
```
