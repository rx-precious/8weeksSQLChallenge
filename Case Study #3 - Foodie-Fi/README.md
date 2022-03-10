![Image](https://8weeksqlchallenge.com/images/case-study-designs/3.png)

# **Problem Statement**
Subscription based businesses are super popular and Danny realised that there was a large gap in the market - he wanted to create a new streaming service that only had food related content - something like Netflix but with only cooking shows!

Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.

## A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

```SQL
WITH a AS (
  SELECT customer_id, a.plan_id, plan_name, start_date,
    LEAD(start_date) OVER (PARTITION BY customer_id) AS nextSub,
    datediff(LEAD(start_date) OVER (PARTITION BY customer_id), start_date) AS diff
  FROM foodie_fi.subscriptions a
  JOIN foodie_fi.plans b on a.plan_id = b.plan_id
  WHERE customer_id IN (1,2,11,13,15,16,18,19))

SELECT customer_id, plan_id, diff
FROM a
WHERE plan_id = 0;
```
| customer_id | plan_id | diff |
|-------------|---------|------|
|           1 |       0 |    7 |
|           2 |       0 |    7 |
|          11 |       0 |    7 |
|          13 |       0 |    7 |
|          15 |       0 |    7 |
|          16 |       0 |    7 |
|          18 |       0 |    7 |
|          19 |       0 |    7 |

#### Answer
- From the table, each customer of foodie-fi initially subscribed to the trial plan of the company and didnt upgrade nor churned until the trial expired.

```SQL
SELECT  customer_id, plan_name, month(LEAD(start_date) OVER ()) - month(start_date) AS SubscriptionMonths
FROM foodie_fi.subscriptions a
JOIN foodie_fi.plans b on a.plan_id = b.plan_id
WHERE customer_id = 19;
```

| customer_id | plan_name   | SubscriptionMonths |
|-------------|-------------|--------------------|
|          19 | trial       |                  0 |
|          19 | pro monthly |                  2 |
|          19 | pro annual  |               NULL |

#### Answer
- Customer_id 19 subscribed for the pro monthly plan for 2 months after enjoyinf the free tral before migrating to a pro annual plan

```SQL
SELECT customer_id, plan_name, start_date
FROM foodie_fi.subscriptions a
JOIN foodie_fi.plans b on a.plan_id = b.plan_id
WHERE customer_id IN (1,2,11,18);
```
| customer_id | plan_name     | start_date |
|-------------|---------------|------------|
|           1 | trial         | 2020-08-01 |
|           1 | basic monthly | 2020-08-08 |
|           2 | trial         | 2020-09-20 |
|           2 | pro annual    | 2020-09-27 |
|          11 | trial         | 2020-11-19 |
|          11 | churn         | 2020-11-26 |
|          18 | trial         | 2020-07-06 |
|          18 | pro monthly   | 2020-07-13 |

#### Answer
- Customer_id 1, 18, and 2 after enjoying the free trial subscribed for the basic monthly, pro monthly and pro annual subscriptions respectively. Customer 11 churned after the trial period.

```SQL
SELECT customer_id, plan_name, start_date
FROM foodie_fi.subscriptions a
JOIN foodie_fi.plans b on a.plan_id = b.plan_id
WHERE customer_id IN (13,15,16);
```
| customer_id | plan_name     | start_date |
|-------------|---------------|------------|
|          13 | trial         | 2020-12-15 |
|          13 | basic monthly | 2020-12-22 |
|          13 | pro monthly   | 2021-03-29 |
|          15 | trial         | 2020-03-17 |
|          15 | pro monthly   | 2020-03-24 |
|          15 | churn         | 2020-04-29 |
|          16 | trial         | 2020-05-31 |
|          16 | basic monthly | 2020-06-07 |
|          16 | pro annual    | 2020-10-21 |

#### Answer
- Customer_id 13 and 16 subscribed for the basic monthly subscription after the 7-day trial period then moved on to the pro monthly and pro annual subscriptions respectively. Customer 15 churned after the basic monthly subscription.


## B. Data Analysis Questions
### 1. How many customers has Foodie-Fi ever had?
```SQL
SELECT COUNT(DISTINCT customer_id) AS uniqueCustomers
FROM foodie_fi.subscriptions;
```
| uniqueCustomers |
|-----------------|
|            1000 |

#### Answer:
Foode_fi have 1000 unique customers subcribed to their platform.

### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```SQL
SELECT monthname(start_date) AS Month, COUNT(*) AS nTrialSubscriptions
FROM foodie_fi.subscriptions
WHERE plan_id = 0
GROUP BY 1
ORDER BY month(start_date);
```

| Month     | nTrialSubscriptions |
|-----------|---------------------|
| January   |                  88 |
| February  |                  68 |
| March     |                  94 |
| April     |                  81 |
| May       |                  88 |
| June      |                  79 |
| July      |                  89 |
| August    |                  88 |
| September |                  87 |
| October   |                  79 |
| November  |                  75 |
| December  |                  84 |

#### Answer
- Foode_fi had the highest number of new subscribers in the month of March.

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
```SQL
SELECT a.plan_id, b.plan_name, COUNT(*) AS nPlan
FROM foodie_fi.subscriptions a
JOIN foodie_fi.plans b ON a.plan_id = b.plan_id
WHERE year(start_date) > 2020
GROUP BY 1
ORDER BY 1;
```
| plan_id | plan_name     | nPlan |
|---------|---------------|-------|
|       1 | basic monthly |     8 |
|       2 | pro monthly   |    60 |
|       3 | pro annual    |    63 |
|       4 | churn         |    71 |

#### Answer
- There was no new subscriber after the year 2020. 71 subscribers churned, 63, 60 and 8 subcribers
migrated to the pro annual, pro monthly and basic monthly respectively.

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```SQL
WITH lostCustomersTable AS (
	SELECT COUNT(*) nChurnedCustomers
	FROM foodie_fi.subscriptions
    WHERE plan_id = 4
  )

SELECT nChurnedCustomers, ROUND(nChurnedCustomers/COUNT(DISTINCT customer_id) * 100, 1) AS PercentageChurned
FROM foodie_fi.subscriptions, lostCustomersTable;
```
| nChurnedCustomers | PercentageChurned |
|-------------------|-------------------|
|               307 |              30.7 |

#### Answer
- A total of 307 subscribers churned representing 30.7% of the total subcribers of Foodie Fi.

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```SQL
WITH trialCusTable AS (
	SELECT *
	FROM foodie_fi.subscriptions
	WHERE plan_id = 0),
	churnCusTable AS (
    SELECT *
    FROM foodie_fi.subscriptions
	WHERE plan_id = 4),
	ChurnCountTable AS (
    SELECT COUNT(*) AS nChurned
	FROM trialCusTable a
	JOIN churnCusTable b ON a.customer_id = b.customer_id
	WHERE datediff(b.start_date, a.start_date) <= 7)

SELECT nChurned, ROUND(nCHurned/COUNT(DISTINCT customer_id) * 100, 0) AS PercentageChurned
FROM foodie_fi.subscriptions, churnCountTable ;
```
| nChurned | PercentageChurned |
|----------|-------------------|
|       92 |                 9 |

#### Answer
- A total of 90 subscribers churned immediately after the free trial representing 9% of the total subscribers of Foodie Fi.


### 6. What is the number and percentage of customer plans after their initial free trial?

```SQL
WITH newPlanTable AS (
	SELECT customer_id, plan_id, LEAD(plan_id) OVER (PARTITION BY customer_id) AS newPlan
	FROM foodie_fi.subscriptions),
	totalCustomerTable AS (
    SELECT COUNT(DISTINCT Customer_id) TotalCustomers
    FROM foodie_fi.subscriptions
	)
SELECT newPlan, COUNT(*) AS nConverted, ROUND(COUNT(*)/TotalCustomers * 100, 1) AS PercentageConverted
FROM newPlanTable, totalCustomerTable
WHERE newPlan IS NOT NULL AND plan_id = 0
GROUP BY 1;
```
| newPlan | nConverted | PercentageConverted |
|---------|------------|---------------------|
|       1 |        546 |                54.6 |
|       2 |        325 |                32.5 |
|       3 |         37 |                 3.7 |
|       4 |         92 |                 9.2 |


### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```SQL
WITH lastPlanTable AS (
	SELECT customer_id, MAX(start_date) AS start_date
	FROM foodie_fi.subscriptions
	WHERE year(start_date) = 2020
	GROUP BY 1),
    nCustomers AS (
	SELECT COUNT(DISTINCT customer_id) AS nCust
	FROM foodie_fi.subscriptions
	WHERE year(start_date) = 2020)

SELECT c.plan_name, COUNT(*) AS nCustomers , ROUND(COUNT(*)/nCust * 100,1) as Percentage
FROM lastPlanTable a
JOIN foodie_fi.subscriptions b ON a.customer_id = b.customer_id AND a.start_date = b.start_date
CROSS JOIN nCustomers
JOIN foodie_fi.plans c ON b.plan_id = c.plan_id
GROUP BY 1
ORDER BY b.plan_id;
```

| plan_name     | nCustomers | Percentage |
|---------------|------------|------------|
| trial         |         19 |        1.9 |
| basic monthly |        224 |       22.4 |
| pro monthly   |        326 |       32.6 |
| pro annual    |        195 |       19.5 |
| churn         |        236 |       23.6 |

#### Answer
- As at the end of year 2020, 32.6% of Foodie Fi subcribers were on the pro monthly subscription representing the highest subscribed plan.


### 8. How many customers have upgraded to an annual plan in 2020?
```SQL
WITH a AS (
	SELECT customer_id, plan_id, LEAD(plan_id) OVER (PARTITION BY customer_id) AS newPlan
	FROM foodie_fi.subscriptions
	WHERE year(start_date) = 2020)

SELECT COUNT(*) AS nCount
FROM a
WHERE newPlan = 3;
```

| nCount |
|--------|
|    195 |
#### Answer
- A total of 195 subscribers had upgraded to an annual plan in the year 2020

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```SQL
WITH trialTable AS (
	SELECT *
	FROM foodie_fi.subscriptions
	WHERE plan_id = 0),
	annualTable AS (
    SELECT *
    FROM foodie_fi.subscriptions
	WHERE plan_id = 3)

SELECT ROUND(AVG(datediff(b.start_date, a.start_date)), 0) AS averageDays
FROM trialTable a
JOIN annualTable b ON a.customer_id = b.customer_id;
```
| averageDays |
|-------------|
|         105 |

#### Answer
--It takes an average of 105 days for a customer to upgrade to the pro annual sunscription.

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```SQL
WITH trialTable AS (
	SELECT *
	FROM foodie_fi.subscriptions
	WHERE plan_id = 0),
	annualTable AS (
    SELECT *
    FROM foodie_fi.subscriptions
	WHERE plan_id = 3),
    periods AS (
    SELECT a.customer_id,
		CASE
			WHEN CEIL(datediff(b.start_date, a.start_date)/30) = 1
				THEN CONCAT(CEIL(datediff(b.start_date, a.start_date)/30) - 1, ' - ', CEIL(datediff(b.start_date, a.start_date)/30) * 30 , ' days')
			ELSE CONCAT((CEIL(datediff(b.start_date, a.start_date)/30) - 1) *30 + 1, ' - ', CEIL(datediff(b.start_date, a.start_date)/30) * 30 , ' days')
            END AS periods,
		(CEIL(datediff(b.start_date, a.start_date)/30) - 1) *30 + 1 AS OrderColumn
	FROM trialTable a
	JOIN annualTable b ON a.customer_id = b.customer_id
	GROUP BY 1)

SELECT periods, COUNT(*) nCustomers
FROM periods
GROUP BY 1
ORDER BY OrderColumn ;
```
| periods        | nCustomers |
|----------------|------------|
| 0 - 30 days    |         49 |
| 31 - 60 days   |         24 |
| 61 - 90 days   |         34 |
| 91 - 120 days  |         35 |
| 121 - 150 days |         42 |
| 151 - 180 days |         36 |
| 181 - 210 days |         26 |
| 211 - 240 days |          4 |
| 241 - 270 days |          5 |
| 271 - 300 days |          1 |
| 301 - 330 days |          1 |
| 331 - 360 days |          1 |

#### Answer
- The frequency distribution looks right skewed meaning most of the subcribers of Foodie Fi that upgraded to the annual plan did so early.

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```SQL
WITH a AS (
	SELECT *, LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY plan_id) AS downPlan_id
	FROM foodie_fi.subscriptions
    WHERE year(start_date) <= 2020
	)
SELECT COUNT(*) AS nDowngradeCust
FROM a
WHERE plan_id = 2 AND downPlan_id = 1;
```
| nDowngradeCust |
|----------------|
|              0 |

#### Answer
- No customer downgraded from the pro monthly to basic monthly in the year 2020.
