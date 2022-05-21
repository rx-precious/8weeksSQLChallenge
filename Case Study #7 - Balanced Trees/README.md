![Image](https://8weeksqlchallenge.com/images/case-study-designs/7.png)

# **Problem Statement**
The business generated a revenue of from the products of unique products. The transaction penetration for all products sold by Balanced Trees are around 49-52% which represents the probability of a product in a transaction.

## High Level Sales Analysis
#### 1. What was the total quantity sold for all products?
```SQL
SELECT SUM(qty) AS totalQty
FROM balanced_tree.sales;
```
| totalQty |
|----------|
|    45216 |

#### 2. What is the total generated revenue for all products before discounts?
```SQL
SELECT SUM(qty*price) AS totalRev
FROM balanced_tree.sales;
```
| totalRev |
|----------|
|  1289453 |


#### 3. What was the total discount amount for all products?
```SQL
SELECT SUM(discount/100 * qty * price) AS totalDiscount
FROM balanced_tree.sales;
```
| totalDiscount |
|---------------|
|   156229.1400 |

#### Transaction Analysis
#### 1. How many unique transactions were there?
```SQL
SELECT COUNT(DISTINCT txn_id) AS UniqueTransaction
FROM balanced_tree.sales;
```
| UniqueTransaction |
|-------------------|
|              2500 |

#### 2. What is the average unique products purchased in each transaction?
```SQL
WITH UniqueProd AS (
	SELECT txn_id, COUNT(DISTINCT prod_id) AS counts
	FROM balanced_tree.sales
	GROUP BY 1)
SELECT ROUND(AVG(counts), 0) AS avgProducts
FROM UniqueProd;
```
| avgProducts |
|-------------|
|           6 |

#### 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
#### 4. What is the average discount value per transaction?
```SQL
WITH UniqueTransactionTable AS (
	SELECT txn_id, SUM(discount/100*qty*price) AS totalDiscount
	FROM balanced_tree.tsales
	GROUP BY 1)

SELECT ROUND(AVG(totalDiscount),2) AS avgDiscount
FROM UniqueTransactionTable;
```
| avgDiscount |
|-------------|
|       62.49 |

#### 5. What is the percentage split of all transactions for members vs non-members?
```SQL
WITH split AS (
	SELECT member, COUNT(DISTINCT txn_id) AS memberCategory
	FROM balanced_tree.sales
	GROUP BY 1),
    UniqueTrans AS (
    SELECT COUNT(DISTINCT txn_id) AS UniqueTransaction
	FROM balanced_tree.sales)
SELECT CASE
	WHEN member = 0 THEN 'Not a Member'
    ELSE 'Member' END AS MemberStatus, ROUND(memberCategory/UniqueTransaction * 100, 1) AS percentage
FROM split, UniqueTrans;
```
| MemberStatus  | percentage |
|---------------|------------|
| Not a Member  |       39.8 |
| Member        |       60.2 |

#### 6. What is the average revenue for member transactions and non-member transactions?
```SQL
WITH rev AS (
SELECT member, SUM(qty * price) AS totalRev
FROM balanced_tree.sales
GROUP BY 1),
	split AS (
	SELECT member, COUNT(DISTINCT txn_id) AS memberCategoryCount
	FROM balanced_tree.sales
	GROUP BY 1)
SELECT CASE
	WHEN rev.member = 0 THEN 'Not a Memeber'
    ELSE 'Member' END AS MemberStatus, ROUND(totalRev/memberCategoryCount, 2) AS AvgRevenue
FROM rev
JOIN split ON rev.member = split.member;
```
| MemberStatus  | AvgRevenue |
|---------------|------------|
| Member        |     516.27 |
| Not a Memeber |     515.04 |

### Product Analysis
CREATE TEMPORARY TABLE SalesProdDetails AS
	SELECT *
	FROM balanced_tree.sales a
	JOIN balanced_tree.product_details b ON a.prod_id = b.product_id;



#### 1. What are the top 3 products by total revenue before discount?
```SQL
WITH prodRev AS (SELECT prod_id, SUM(qty*price) AS TotalRevenue
FROM balanced_tree.sales
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3)
SELECT b.product_name, a.totalRevenue
FROM prodRev a
JOIN balanced_tree.product_details b ON a.prod_id = b.product_id;
```
| product_name                 | totalRevenue |
|------------------------------|--------------|
| Grey Fashion Jacket - Womens |       209304 |
| White Tee Shirt - Mens       |       152000 |
| Blue Polo Shirt - Mens       |       217683 |

#### 2. What is the total quantity, revenue and discount for each segment?
```SQL
SELECT b.segment_name, SUM(a.qty) AS qtySold, SUM(a.qty * a.price) AS TotalRev , ROUND(SUM(discount/100 * a.qty * a.price), 2) AS totalDiscount
FROM balanced_tree.sales a
JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
GROUP BY 1;
```
| segment_name | qtySold | TotalRev | totalDiscount |
|--------------|---------|----------|---------------|
| Jeans        |   11349 |   208350 |      25343.97 |
| Shirt        |   11265 |   406143 |      49594.27 |
| Socks        |   11217 |   307977 |      37013.44 |
| Jacket       |   11385 |   366983 |      44277.46 |


#### 3. What is the top selling product for each segment?
```SQL
WITH ranking AS (
	SELECT b.segment_name, b.product_name, SUM(a.qty * a.price) AS totalREv,
		DENSE_RANK() OVER(PARTITION BY b.segment_name ORDER BY SUM(a.qty * a.price) DESC) AS ranking
	FROM balanced_tree.sales a
	JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
	GROUP BY 1,2)
SELECT  segment_name, product_name, totalRev
FROM ranking
WHERE ranking = 1;
```
| segment_name | product_name                  | totalRev |
|--------------|-------------------------------|----------|
| Jacket       | Grey Fashion Jacket - Womens  |   209304 |
| Jeans        | Black Straight Jeans - Womens |   121152 |
| Shirt        | Blue Polo Shirt - Mens        |   217683 |
| Socks        | Navy Solid Socks - Mens       |   136512 |

#### 4. What is the total quantity, revenue and discount for each category?
```SQL
SELECT b.category_name, SUM(a.qty) AS qtySold, SUM(a.qty * a.price) AS TotalRev , ROUND(SUM(discount/100 * a.qty * a.price), 2) AS totalDiscount
FROM balanced_tree.sales a
JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
GROUP BY 1;
```
| category_name | qtySold | TotalRev | totalDiscount |
|---------------|---------|----------|---------------|
| Womens        |   22734 |   575333 |      69621.43 |
| Mens          |   22482 |   714120 |      86607.71 |

#### 5. What is the top selling product for each category?
```SQL
WITH ranking AS (
	SELECT b.category_name, b.product_name, SUM(a.qty * a.price) AS totalREv,
		DENSE_RANK() OVER(PARTITION BY b.category_name ORDER BY SUM(a.qty * a.price) DESC) AS ranking
	FROM balanced_tree.sales a
	JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
	GROUP BY 1,2)
SELECT  category_name, product_name, totalRev
FROM ranking
WHERE ranking = 1;
```
| category_name | product_name                 | totalRev |
|---------------|------------------------------|----------|
| Mens          | Blue Polo Shirt - Mens       |   217683 |
| Womens        | Grey Fashion Jacket - Womens |   209304 |
#### 6. What is the percentage split of revenue by product for each segment?
```SQL
WITH a AS (
	SELECT segment_name, product_name, sum(qty*a.price) AS Total_Price
	FROM balanced_tree.sales a
	JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
	GROUP BY 1,2)

SELECT *,  ROUND(total_price/sum(total_price) OVER(PARTITION BY segment_name) * 100, 2) AS Percentage
FROM a
ORDER BY 1,4;
```
| segment_name | product_name                     | Total_Price | Percentage |
|--------------|----------------------------------|-------------|------------|
| Jacket       | Indigo Rain Jacket - Womens      |       71383 |      19.45 |
| Jacket       | Khaki Suit Jacket - Womens       |       86296 |      23.51 |
| Jacket       | Grey Fashion Jacket - Womens     |      209304 |      57.03 |
| Jeans        | Cream Relaxed Jeans - Womens     |       37070 |      17.79 |
| Jeans        | Navy Oversized Jeans - Womens    |       50128 |      24.06 |
| Jeans        | Black Straight Jeans - Womens    |      121152 |      58.15 |
| Shirt        | Teal Button Up Shirt - Mens      |       36460 |       8.98 |
| Shirt        | White Tee Shirt - Mens           |      152000 |      37.43 |
| Shirt        | Blue Polo Shirt - Mens           |      217683 |      53.60 |
| Socks        | White Striped Socks - Mens       |       62135 |      20.18 |
| Socks        | Pink Fluro Polkadot Socks - Mens |      109330 |      35.50 |
| Socks        | Navy Solid Socks - Mens          |      136512 |      44.33 |

#### 7. What is the percentage split of revenue by segment for each category?
```SQL
WITH a AS (
	SELECT category_name, segment_name, sum(qty*a.price) AS Total_Price
	FROM balanced_tree.sales a
	JOIN balanced_tree.product_details b ON a.prod_id = b.product_id
	GROUP BY 1,2)


SELECT *,  ROUND(total_price/sum(total_price) OVER(PARTITION BY category_name) * 100, 2) AS Percentage
FROM a
ORDER BY 1,4;
```
| category_name | segment_name | Total_Price | Percentage |
|---------------|--------------|-------------|------------|
| Mens          | Socks        |      307977 |      43.13 |
| Mens          | Shirt        |      406143 |      56.87 |
| Womens        | Jeans        |      208350 |      36.21 |
| Womens        | Jacket       |      366983 |      63.79 |

#### 8. What is the percentage split of total revenue by category
```SQL
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
```
| category_name | Percentage |
|---------------|------------|
| Womens        |      44.62 |
| Mens          |      55.38 |

#### 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
```SQL
WITH a AS (
SELECT prod_id, COUNT(*) AS nTransactions
FROM balanced_tree.sales
GROUP BY 1),
	b AS (
    SELECT COUNT(DISTINCT txn_id) AS totalTransactions
    FROM balanced_tree.sales)

SELECT a.prod_id, b.product_name, nTransactions/totalTransactions
FROM a, b
JOIN balanced_tree.product_details c ON a.prod_id = c.product_id;
```
| product_name                     | TransactionPenetration |
|----------------------------------|------------------------|
| Navy Oversized Jeans - Womens    |                 0.5096 |
| Black Straight Jeans - Womens    |                 0.4984 |
| Cream Relaxed Jeans - Womens     |                 0.4972 |
| Khaki Suit Jacket - Womens       |                 0.4988 |
| Indigo Rain Jacket - Womens      |                 0.5000 |
| Grey Fashion Jacket - Womens     |                 0.5100 |
| White Tee Shirt - Mens           |                 0.5072 |
| Teal Button Up Shirt - Mens      |                 0.4968 |
| Blue Polo Shirt - Mens           |                 0.5072 |
| Navy Solid Socks - Mens          |                 0.5124 |
| White Striped Socks - Mens       |                 0.4972 |
| Pink Fluro Polkadot Socks - Mens |                 0.5032 |

#### 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
```SQL
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
```
| prodOne                      | prodTwo                     | prodThree              | timesCombined |
|------------------------------|-----------------------------|------------------------|---------------|
| Grey Fashion Jacket - Womens | Teal Button Up Shirt - Mens | White Tee Shirt - Mens |           352 |

The most common combination of any 3 products bought in a single transaction was - Grey Fashion Jacket - Womens, Teal Button Up Shirt - Mens and White Tee Shirt - Mens
