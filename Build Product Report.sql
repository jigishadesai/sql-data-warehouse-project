/*
==============================================================================================
Product Report
==============================================================================================
Purpose: This report consolidates key product metrics and behaviors

Highlights:
1. Gather essential fields like product name, category, subcategory, cost 
2. Segment products by revenue to identify High-Performers, Mid-Range or Low-Performers
3. Aggreagte product level metrics:
	-Total Orders
	-Total Sales
	-Total Quantity sold
	-Total unique customers
	-Life span (in months)
4. Calculate valuable KPIs
	-Recency (month since last sale)
	-average order revenue
	-average monthly revenue

==============================================================================================
*/
--DROP VIEW gold.product_report;
CREATE VIEW gold.product_report AS
WITH base_query AS(

--1. Base Query : Retrieve the required columns

	SELECT 
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost,
	s.order_number,
	s.customer_key,
	s.sales_amount,
	s.quantity,
	s.order_date
	FROM gold.fact_sales s
	LEFT JOIN
	gold.dim_products p
	ON s.product_key = p.product_key
	WHERE order_date IS NOT NULL)
, product_aggregation AS
(
--2. product aggregation: summarizes key metrics at the product level
	SELECT 
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		COUNT(DISTINCT order_number) total_orders,
		SUM(sales_amount) total_revenue, 
		SUM(quantity) total_qty,
		COUNT(DISTINCT customer_key) total_customers,
		MAX(order_date) last_order_date,
		DATEDIFF(month,MIN(order_date),MAX(order_date)) life_span
		FROM base_query
	GROUP BY product_key, product_name, category, subcategory, cost
)
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	total_revenue,
	CASE 
		WHEN total_revenue < 10000 THEN 'Low-Performer'
		WHEN total_revenue BETWEEN 10000 AND 50000 THEN 'Mid-Range' 
		ELSE 'High-Perforer'
	END product_segment,
	last_order_date,
	DATEDIFF(month, last_order_date, GETDATE()) AS recency,
	total_orders,
	total_qty,
	total_customers,
	life_span,

	--Calculate AOR
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE (total_revenue / total_orders)
	END AS avg_order_revenue, 

	--Calculate average monthly revenue
	CASE 
		WHEN life_span = 0 THEN total_revenue
		ELSE (total_revenue / life_span)
	END AS avg_monthly_revenue
	
FROM product_aggregation;

--SELECT * FROM gold.product_report

