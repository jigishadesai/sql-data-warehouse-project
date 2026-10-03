--------1 Changes over time analysis----------------------

--Analyse sales performance over time--

--Year wise--
SELECT YEAR(order_date) order_year,
COUNT(DISTINCT customer_key) total_customers,
SUM(quantity) total_qty,
SUM(sales_amount) total_sales
FROM gold.fact_sales
WHERE order_Date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY 1 

--Month wise--
SELECT MONTH(order_date) order_month,
COUNT(DISTINCT customer_key) total_customers,
SUM(quantity) total_qty,
SUM(sales_amount) total_sales
FROM gold.fact_sales
WHERE order_Date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY 4 DESC 


--Year and Month wise---

SELECT DATETRUNC(month,order_date) order_month_year,
COUNT(DISTINCT customer_key) total_customers,
SUM(quantity) total_qty,
SUM(sales_amount) total_sales
FROM gold.fact_sales
WHERE order_Date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
ORDER BY 1


SELECT FORMAT(order_date, 'yyyy-MMM') order_month_year,
COUNT(DISTINCT customer_key) total_customers,
SUM(quantity) total_qty,
SUM(sales_amount) total_sales
FROM gold.fact_sales
WHERE order_Date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY 1


--------2 Cumulative analysis----------------------

-------Aggreagte the data progressively over the time--

--Calculate total sales per month and running total of sales over time

SELECT order_date,
total_sales,
SUM(total_sales) OVER( PARTITION BY order_date ORDER BY order_date) running_total_sales 
--default window frame i.e. UNBOUNDED PRECEDING AND CURRENT ROW
FROM
(
SELECT DATETRUNC(month,order_date) order_date,
SUM(sales_amount) total_Sales
FROM gold.fact_sales
WHERE order_Date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
)t
ORDER BY 1

--Calculate total sales per year and running total of sales over time

SELECT order_date,
total_sales,
SUM(total_sales) OVER( ORDER BY order_date) running_total_sales 
--default window frame i.e. UNBOUNDED PRECEDING AND CURRENT ROW
FROM
(
SELECT DATETRUNC(year,order_date) order_date,
SUM(sales_amount) total_Sales
FROM gold.fact_sales
WHERE order_Date IS NOT NULL
GROUP BY DATETRUNC(year,order_date)
)t
ORDER BY 1


--Calculate moving avg over time

SELECT order_date,
total_sales,
SUM(total_sales) OVER( ORDER BY order_date) running_total_sales ,
avg_price,
AVG(avg_price) OVER( ORDER BY order_date) moving_avg
--default window frame i.e. UNBOUNDED PRECEDING AND CURRENT ROW
FROM
(
SELECT DATETRUNC(year,order_date) order_date,
SUM(sales_amount) total_sales,
AVG(price) avg_price
FROM gold.fact_sales
WHERE order_Date IS NOT NULL
GROUP BY DATETRUNC(year,order_date)
)t
ORDER BY 1


--------3 Performance analysis----------------------
--Comparing the current value to the target value---


--Analyse the yearly performance of products by comparing their sales to both avg sales
--and previous year's sales

WITH yearly_product_sales AS
(
	SELECT YEAR(order_date) order_year,
	product_name, 
	SUM(sales_amount) current_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON p.product_key = s.product_key
	WHERE S.order_date IS NOT NULL
	GROUP BY product_name, YEAR(order_date) 
)
SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) avg_sales,
current_sales - AVG(current_sales) OVER(PARTITION BY product_name) as diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
	 WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
	 ELSE 'Avg'
END avg_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) py_sales,
--Year over year analysis--
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	 ELSE 'No Change'
END py_change
FROM yearly_product_sales
ORDER BY product_name,order_year

--------4 Part to whole analysis(Proportional Analysis)----------------------

--Which category contribute the most to the overall sales

WITH category_sales AS
(
	SELECT category,
	SUM(sales_amount) category_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON p.product_key = s.product_key
	GROUP BY category
)
SELECT category, c.category_sales, 
SUM(c.category_sales) OVER() total_sales,
CONCAT(ROUND((CAST(c.category_sales  AS float)/ SUM(c.category_sales) OVER()) *100,2),'%') percentage_of_total
FROM category_sales c
ORDER BY 2 DESC

--------5 Data Segmentation----------------------
--Group the data based on speicific range 
--Helps understand the correlation between two measures


--Segment prodcuts into cost ranges and count how many products fall in to each segment

WITH product_segment AS
(
SELECT product_key,product_name, cost,
CASE WHEN cost < 100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN cost BETWEEN 501 AND 1000 THEN '501-1000'
	 ELSE 'Above 1000'
END cost_range
FROM gold.dim_products
)
SELECT cost_range, COUNT(product_key) product_count
FROM product_segment
GROUP BY cost_range
ORDER BY 2 DESC

--Group customers into three based on their spending behaviour
--VIP : Atleast 12 months of history and spending more than 5000
--Regular : Atleast 12 months of history and but spending 5000 or less
--New : life span less than 12 months
--Find total customers by each group

WITH customer_spending AS
(
	SELECT customer_key, SUM(sales_amount) total_spending, 
	MIN(order_date) first_order, MAX(order_date) last_order,
	DATEDIFF(month,MIN(order_date),MAX(order_date)) life_span
	FROM gold.fact_sales
	GROUP BY customer_key),
derive_customer_segments AS
(
	SELECT customer_key, total_spending, life_span,
	CASE WHEN life_span >= 12 AND total_spending > 5000 THEN 'VIP'
		 WHEN life_Span >= 12 AND total_spending <= 5000 THEN 'Regular'
		 ELSE 'New'
	END customer_segment
	FROM customer_spending)
SELECT customer_segment, COUNT(customer_key) total_customers
FROM derive_customer_segments
GROUP BY customer_segment
ORDER BY 2 DESC
