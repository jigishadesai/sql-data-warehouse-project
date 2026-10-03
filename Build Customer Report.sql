/*
==============================================================================================
Customer Report
==============================================================================================
Purpose: This report consolidates key customer metrics and behaviors

Highlights:
1. Gather essential fields like name, ages and transaction details
2. Segment customers into categories (VIP,Regular,New) and age groups.
3. Aggreagte customer level metrics:
	-Total Orders
	-Total Sales
	-Total Quantity purchased
	-Total Products
	-Life span (in months)
4. Calculate valuable KPIs
	-Recency (month since last order)
	-average order value
	-average monthly spend

==============================================================================================
*/
CREATE VIEW gold.customer_report AS
WITH base_query AS(

--1. Base Query : Retrieve the required columns

	SELECT 
		c.customer_key, 
		c.customer_number, 
		CONCAT(c.first_name,' ', c.last_name) AS customer_name,
		DATEDIFF(year,c.birthdate,GETDATE()) age,
		s.order_number,
		s.order_date, 
		s.sales_amount, 
		s.quantity,
		s.product_key
	FROM gold.fact_sales s
	LEFT JOIN
	gold.dim_customers c
	ON s.customer_key = c.customer_key
	WHERE order_date IS NOT NULL)
, customer_aggregation AS
(
--2. Customer aggregation: summarizes key metrics at the customer level
	SELECT 
		customer_key, 
		customer_number, 
		customer_name,
		age,
		COUNT(DISTINCT order_number) total_orders,
		SUM(sales_amount) total_spending, 
		SUM(quantity) total_qty,
		COUNT(DISTINCT product_key) total_product,
		MAX(order_date) last_order_date,
		DATEDIFF(month,MIN(order_date),MAX(order_date)) life_span
	FROM base_query
	GROUP BY customer_key, customer_number, customer_name, age
)
SELECT
	customer_key, 
	customer_number, 
	customer_name,
	age,
	CASE 
		WHEN age < 20 THEN 'Below 20'
		 WHEN age BETWEEN 20 AND 29 THEN '20-29'
		 WHEN age BETWEEN 30 AND 39 THEN '30-39'
		 WHEN age BETWEEN 40 AND 49 THEN '40-49'
		 ELSE 'Above 50'
	END age_group,
	CASE 
		WHEN life_span >= 12 AND total_spending > 5000 THEN 'VIP'
		WHEN life_Span >= 12 AND total_spending <= 5000 THEN 'Regular'
		ELSE 'New'
	END customer_segment,
	last_order_date,
	DATEDIFF(month, last_order_date, GETDATE()) AS recency,
	total_orders,
	total_qty,
	total_product,
	life_span,

	--Calculate AOV
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE (total_spending / total_orders)
	END AS avg_order_value, 

	--Calculate average monthly spend
	CASE 
		WHEN life_span = 0 THEN total_spending
		ELSE (total_spending / life_span)
	END AS avg_monthly_spend
	
FROM customer_aggregation

--SELECT * FROM gold.customer_report



