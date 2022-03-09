-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

WITH a AS (SELECT customer_id, a.plan_id, plan_name, start_date,
	LEAD(start_date) OVER (PARTITION BY customer_id) AS nextSub,
    datediff(LEAD(start_date) OVER (PARTITION BY customer_id), start_date) AS diff
FROM foodie_fi.subscriptions a
JOIN foodie_fi.plans b on a.plan_id = b.plan_id
WHERE customer_id IN (1,2,11,13,15,16,18,19))

SELECT customer_id, plan_id, diff
FROM a
WHERE plan_id = 0 ;


SELECT *, month(LEAD(start_date) OVER ()) - month(start_date) AS SubscriptionDays
FROM foodie_fi.subscriptions a
JOIN foodie_fi.plans b on a.plan_id = b.plan_id
WHERE customer_id = 19;

SELECT customer_id, plan_name, start_date
FROM foodie_fi.subscriptions a
JOIN foodie_fi.plans b on a.plan_id = b.plan_id
WHERE customer_id IN (1,2,11,18);

SELECT customer_id, plan_name, start_date
FROM foodie_fi.subscriptions a
JOIN foodie_fi.plans b on a.plan_id = b.plan_id
WHERE customer_id IN (13,15,16);

-- B. Data Analysis Questions

-- How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id)
FROM foodie_fi.subscriptions;

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT monthname(start_date) AS Month, COUNT(*) AS nTrialSubscriptions
FROM foodie_fi.subscriptions
WHERE plan_id = 0
GROUP BY 1
ORDER BY month(start_date);

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT a.plan_id, plan_name, COUNT(*) AS nPlan
FROM foodie_fi.subscriptions a
JOIN foodie_fi.plans b ON a.plan_id = b.plan_id
WHERE year(start_date) > 2020
GROUP BY 1;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
WITH lostCustomersTable AS (
	SELECT COUNT(*) nChurnedCustomers
	FROM foodie_fi.subscriptions
    WHERE plan_id = 4
    )

SELECT nChurnedCustomers, ROUND(nChurnedCustomers/COUNT(DISTINCT a.customer_id) * 100, 1) AS PercentageChurned
FROM foodie_fi.subscriptions a
CROSS JOIN lostCustomersTable b;

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH a AS (
	SELECT *
	FROM foodie_fi.subscriptions
	WHERE plan_id = 0),
	b AS (
    SELECT *
    FROM foodie_fi.subscriptions
	WHERE plan_id = 4),
	c AS (
    SELECT COUNT(*) AS nChurned
	FROM a
	JOIN b ON a.customer_id = b.customer_id
	WHERE datediff(b.start_date, a.start_date) <= 7)

SELECT nChurned, ROUND(nCHurned/COUNT(DISTINCT a.customer_id) * 100, 0) AS PercentageChurned
FROM foodie_fi.subscriptions a
CROSS JOIN c;

-- What is the number and percentage of customer plans after their initial free trial?

WITH a AS (
	SELECT customer_id, plan_id, LEAD(plan_id) OVER (PARTITION BY customer_id) AS newPlan
	FROM foodie_fi.subscriptions),
	b AS (
    SELECT COUNT(DISTINCT Customer_id) TotalCustomers
    FROM foodie_fi.subscriptions
	)
SELECT newPlan, COUNT(*) AS nConverted, ROUND(COUNT(*)/TotalCustomers * 100, 1) AS PercentageConverted
FROM a
CROSS JOIN b
WHERE newPlan IS NOT NULL AND plan_id = 0
GROUP BY 1;
;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
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


-- How many customers have upgraded to an annual plan in 2020?
WITH a AS (
	SELECT customer_id, plan_id, LEAD(plan_id) OVER (PARTITION BY customer_id) AS newPlan
	FROM foodie_fi.subscriptions
	WHERE year(start_date) = 2020)

SELECT COUNT(*)
FROM a
WHERE newPlan = 3;

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
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

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
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

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH a AS (
	SELECT *, LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY plan_id) AS downPlan_id
	FROM foodie_fi.subscriptions
    WHERE year(start_date) <= 2020
	)
SELECT COUNT(*) AS nDowngradeCust
FROM a
WHERE plan_id = 2 AND downPlan_id = 1;
