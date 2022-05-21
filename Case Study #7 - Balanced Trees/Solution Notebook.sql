
-- High Level Sales Analysis
-- 1. What was the total quantity sold for all products?
SELECT SUM(qty) AS totalQty
FROM balanced_tree.sales;


-- 2. What is the total generated revenue for all products before discounts?
SELECT SUM(qty*price) AS totalRev
FROM balanced_tree.sales;


-- 3. What was the total discount amount for all products?
SELECT SUM(discount/100 * qty * price) AS totalDiscount
FROM balanced_tree.sales;


-- Transaction Analysis
-- 1. How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS UniqueTransaction
FROM balanced_tree.sales;


-- 2. What is the average unique products purchased in each transaction?
WITH UniqueProd AS (
	SELECT txn_id, COUNT(DISTINCT prod_id) AS counts
	FROM balanced_tree.sales
	GROUP BY 1)
SELECT ROUND(AVG(counts), 0) AS avgProducts
FROM UniqueProd;


-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
-- 4. What is the average discount value per transaction?
WITH UniqueTransactionTable AS (
	SELECT txn_id, SUM(discount/100*qty*price) AS totalDiscount
	FROM balanced_tree.tsales
	GROUP BY 1)

SELECT ROUND(AVG(totalDiscount),2) AS avgDiscount
FROM UniqueTransactionTable;


-- 5. What is the percentage split of all transactions for members vs non-members?
WITH split AS (
	SELECT member, COUNT(DISTINCT txn_id) AS memberCategory
	FROM balanced_tree.sales
	GROUP BY 1),
    UniqueTrans AS (
    SELECT COUNT(DISTINCT txn_id) AS UniqueTransaction
	FROM balanced_tree.sales)
SELECT CASE
	WHEN member = 0 THEN 'Not a Memeber'
    ELSE 'Member' END AS MemberStatus, ROUND(memberCategory/UniqueTransaction * 100, 1) AS percentage
FROM split, UniqueTrans;


-- 6. What is the average revenue for member transactions and non-member transactions?
WITH rev AS (
SELECT member, SUM(qty * price) AS totalRev
FROM balanced_tree.sales
GROUP BY 1),
	split AS (
	SELECT member, COUNT(DISTINCT txn_id) AS memberCategory
	FROM balanced_tree.sales
	GROUP BY 1)
SELECT CASE
	WHEN rev.member = 0 THEN 'Not a Memeber'
    ELSE 'Member' END AS MemberStatus, ROUND(totalRev/memberCategory, 2) AS AvgRevenue
FROM rev
JOIN split ON rev.member = split.member;


-- Product Analysis
-- 1. What are the top 3 products by total revenue before discount?
WITH prodRev AS (SELECT prod_id, SUM(qty*price) AS TotalRevenue
FROM balanced_tree.sales
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3)
SELECT b.product_name, a.totalRevenue
FROM prodRev a
JOIN balanced_tree.product_details b ON a.prod_id = b.product_id;


-- 2. What is the total quantity, revenue and discount for each segment?
SELECT b.segment_name, SUM(a.qty) AS qtySold, SUM(a.qty * a.price) AS TotalRev , ROUND(SUM(discount/100 * a.qty * a.price), 2) AS totalDiscount
FROM balanced_tree.sales a
JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
GROUP BY 1;



-- 3. What is the top selling product for each segment?
WITH ranking AS (
	SELECT b.segment_name, b.product_name, SUM(a.qty * a.price) AS totalREv,
		DENSE_RANK() OVER(PARTITION BY b.segment_name ORDER BY SUM(a.qty * a.price) DESC) AS ranking
	FROM balanced_tree.sales a
	JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
	GROUP BY 1,2)
SELECT  segment_name, product_name, totalRev
FROM ranking
WHERE ranking = 1;


-- 4. What is the total quantity, revenue and discount for each category?
SELECT b.category_name, SUM(a.qty) AS qtySold, SUM(a.qty * a.price) AS TotalRev , ROUND(SUM(discount/100 * a.qty * a.price), 2) AS totalDiscount
FROM balanced_tree.sales a
JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
GROUP BY 1;


-- 5. What is the top selling product for each category?
WITH ranking AS (
	SELECT b.category_name, b.product_name, SUM(a.qty * a.price) AS totalREv,
		DENSE_RANK() OVER(PARTITION BY b.category_name ORDER BY SUM(a.qty * a.price) DESC) AS ranking
	FROM balanced_tree.sales a
	JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
	GROUP BY 1,2)
SELECT  category_name, product_name, totalRev
FROM ranking
WHERE ranking = 1;


-- 6. What is the percentage split of revenue by product for each segment?
WITH a AS (
	SELECT segment_name, product_name, sum(qty*a.price) AS Total_Price
	FROM balanced_tree.sales a
	JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
	GROUP BY 1,2)
SELECT *,  ROUND(total_price/sum(total_price) OVER(PARTITION BY segment_name) * 100, 2) AS Percentage
FROM a
ORDER BY 1,4;


-- 7. What is the percentage split of revenue by segment for each category?
WITH a AS (
	SELECT category_name, segment_name, sum(qty*a.price) AS Total_Price
	FROM balanced_tree.sales a
	JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
	GROUP BY 1,2)
SELECT *,  ROUND(total_price/sum(total_price) OVER(PARTITION BY ca) * 100, 2) AS Percentage
FROM a
ORDER BY 1,4;


-- 8. What is the percentage split of total revenue by category
WITH categoryRev AS (
	SELECT b.category_name, SUM(a.qty * a.price) AS CategoryREv
	FROM balanced_tree.sales a
	JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
    GROUP BY 1),
    totalRev AS (
    SELECT SUM(qty*price) AS totalRev
	FROM balanced_tree.sales)
SELECT category_name, ROUND(CategoryRev/totalRev * 100, 2) AS Percentage
FROM categoryRev, totalRev
GROUP BY 1;


-- 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
WITH a AS (
SELECT prod_id, COUNT(*) AS nTransactions
FROM balanced_tree.sales
GROUP BY 1),
	b AS (
    SELECT COUNT(DISTINCT txn_id) AS totalTransactions
    FROM balanced_tree.sales)

SELECT prod_id, nTransactions/totalTransactions
FROM a, b


-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH product_nameT AS (
	SELECT  a.txn_id, b.product_name
    FROM balanced_tree.sales a
    JOIN balanced_tree.product_details b ON a.prod_id = b.product_id)

SELECT a.product_name AS prodOne , b.product_name AS prodTwo, c.product_name AS prodThree, COUNT(*) AS timesCombined
FROM product_nameT a
JOIN product_nameT b ON a.txn_id = b.txn_id
AND a.product_name <> b.product_name
AND a.product_name < b.product_name
JOIN product_nameT c ON a.txn_id = c.txn_id
	AND c.product_name <> a.product_name
	AND c.product_name <> b.product_name
	AND a.product_name < c.product_name
	AND b.product_name < c.product_name
	GROUP BY 1,2,3
	ORDER BY 4 DESC
    LIMIT 1;
