SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM sales;


-- Report and Data Analysis

-- Q1. Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
city_name,
ROUND((population * 0.25) / 1000000 , 2)
AS coffee_consumers_in_millions,
city_rank
FROM 
city
ORDER BY 2 desc;



-- Q2. Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
on ci.city_id = c.city_id
where
	EXTRACT (YEAR FROM s.sale_date) = 2023
	AND
	EXTRACT (QUARTER FROM s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;



-- Q3. Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) AS total_orders
FROM products AS p
LEFT JOIN sales AS s
ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;



-- Q4. Average Sales Amount per City 
-- What is the average sales amount per customer in each city?

SELECT 
	ci.city_name,
	SUM(s.total) AS total_revenue,
	COUNT(DISTINCT s.customer_id) AS total_cust,
	ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric , 2) AS avg_sales_per_cust
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;



-- Q5. City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.

WITH city_table AS
(
SELECT 
	city_name,
	ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers
FROM city
),

customers_table AS
(
SELECT 
	ci.city_name,
	count(DISTINCT c.customer_id) AS unique_cx
	FROM sales AS s
	JOIN customers AS c
	ON c.customer_id = s.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)

SELECT 
	customers_table.city_name,
	city_table.coffee_consumers AS coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN customers_table
ON city_table.city_name = customers_table.city_name



-- Q6. Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * 
FROM
(
SELECT 
	ci.city_name,
	p.product_name,
	COUNT(s.sale_id) AS total_orders,
	DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank
FROM sales AS s
JOIN products AS p
ON s.product_id = p.product_id
JOIN customers AS c
ON c.customer_id = s.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY 1, 2
)
WHERE rank <= 3;



-- Q7. Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) AS unique_cx
FROM city AS ci
JOIN customers AS c
ON c.city_id = ci.city_id
JOIN sales AS s
ON s.customer_id = s.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;



-- Q8. Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) AS total_revenue,
		COUNT(DISTINCT s.customer_id) AS total_cx,
		ROUND(SUM(s.total)::numeric / 
			  COUNT(DISTINCT s.customer_id)::numeric, 2)
			  AS avg_sale_per_cx
	FROM sales AS s
	JOIN customers AS c
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT
		city_name,
		estimated_rent
	FROM city
)

SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_per_cx,
	ROUND
		(cr.estimated_rent ::numeric / ct.total_cx ::numeric, 2) 
		AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;



-- Q9. Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) AS month,
		EXTRACT(YEAR FROM sale_date) AS year,
		SUM(s.total) AS total_sale
	FROM sales AS s
	JOIN customers AS c
	ON c.customer_id = s.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS 
(
	SELECT 
		city_name,
		month,
		year,
		total_sale as cr_month_sale,
		LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month)
		AS last_month_sale
	FROM monthly_sales
)

SELECT 
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale - last_month_sale)::numeric / last_month_sale ::numeric * 100, 2)
	AS growth_ratio
FROM growth_ratio
WHERE
	last_month_sale IS NOT NULL;



-- Q10. Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer.

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) AS total_revenue,
		COUNT(DISTINCT s.customer_id) AS total_cx,
		ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) 
		AS avg_sale_per_cx
	FROM sales AS s
	JOIN customers AS c
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name,
		estimated_rent,
		ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_cunsumer_in_millions
	FROM city	
)

SELECT
	cr.city_name,
	total_revenue,
	cr.estimated_rent AS total_rent,
	ct.total_cx,
	cr.estimated_coffee_cunsumer_in_millions,
	ct.avg_sale_per_cx,
	ROUND(cr.estimated_rent ::numeric / ct.total_cx ::numeric, 2)
	AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 3 DESC;




	

