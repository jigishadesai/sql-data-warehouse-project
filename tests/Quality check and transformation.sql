-------------------------bronze.crm_cust_info-------------------------------

--Check for NULL or duplicate in Primary key

SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

SELECT *
FROM bronze.crm_cust_info
WHERE cst_id = 29466;


SELECT *
FROM (
SELECT *,  ROW_NUMBER() OVER(PARTITION BY cst_id  ORDER BY cst_create_date DESC ) flag_last
FROM bronze.crm_cust_info) t
WHERE flag_last = 1 AND cst_id = 29466;

----Check for unwanted spaces---

SELECT *
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT *
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT *
FROM bronze.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);


SELECT *
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);


--Data standardization and consistency--

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info


SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info


---TRANSFORMATION---

SELECT cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE UPPER(TRIM(cst_marital_status))
	WHEN 'M' THEN 'Married'
	WHEN 'S' THEN 'Single'
	ELSE 'n/a'
END AS cst_marital_status,
CASE UPPER(TRIM(cst_gndr))
	WHEN 'F' THEN 'Female'
	WHEN 'M' THEN 'Male'
	ELSE 'n/a'
END AS cst_gndr,
cst_create_date
FROM (
SELECT *,  ROW_NUMBER() OVER(PARTITION BY cst_id  ORDER BY cst_create_date DESC ) flag_last
FROM bronze.crm_cust_info) t
WHERE flag_last = 1;

SELECT *
FROM silver.crm_cust_info;


INSERT INTO silver.crm_cust_info(cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date)
SELECT cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE UPPER(TRIM(cst_marital_status))
	WHEN 'M' THEN 'Married'
	WHEN 'S' THEN 'Single'
	ELSE 'n/a'
END AS cst_marital_status,
CASE UPPER(TRIM(cst_gndr))
	WHEN 'F' THEN 'Female'
	WHEN 'M' THEN 'Male'
	ELSE 'n/a'
END AS cst_gndr,
cst_create_date
FROM (
SELECT *,  ROW_NUMBER() OVER(PARTITION BY cst_id  ORDER BY cst_create_date DESC ) flag_last
FROM bronze.crm_cust_info 
WHERE cst_id IS NOT NULL) t
WHERE flag_last = 1;

SELECT *
FROM silver.crm_cust_info;

 
 ------------bronze.crm_prd_info---------------------
  
--Check for NULL or duplicate in Primary key
 SELECT prd_id, COUNT(*)
 FROM bronze.crm_prd_info
 GROUP BY prd_id
 HAVING COUNT(*) > 1 OR prd_id IS NULL;

  
----Check for unwanted spaces---
 SELECT *
 FROM bronze.crm_prd_info
 WHERE prd_nm != TRIM(prd_nm)


 --Data standardization and consistency--
 SELECT DISTINCT prd_line
 FROM bronze.crm_prd_info;

 SELECT *
 FROM bronze.crm_prd_info
 WHERE prd_cost IS NULL;

 
 SELECT *
 FROM bronze.crm_prd_info
 WHERE prd_cost < 0;

 SELECT *
 FROM bronze.crm_prd_info
 WHERE prd_start_dt IS NULL;


 SELECT *
 FROM bronze.crm_prd_info
 WHERE prd_end_dt IS NULL;

 SELECT *
 FROM bronze.crm_prd_info
 WHERE prd_end_dt < prd_start_dt;

 ---TRANSFORMATION---

 SELECT prd_id,
 prd_key,
 prd_nm,
 ISNULL(prd_cost,0) AS prd_cost,
 prd_start_dt,
 LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)- 1 prd_start_dt_new,
 prd_end_dt
 FROM bronze.crm_prd_info
 WHERE prd_key IN ('AC-HE-HL-U509','AC-HE-HL-U509-R');

SELECT prd_id,
 REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
 SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
 prd_nm,
 ISNULL(prd_cost,0) AS prd_cost,
 CASE UPPER(TRIM(prd_line))
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	ELSE 'n/a'
END AS prd_line,
CAST(prd_start_dt AS date) prd_start_dt,
CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)- 1 AS date) prd_end_dt
FROM bronze.crm_prd_info;


 SELECT *
 FROM silver.crm_prd_info;


 INSERT INTO silver.crm_prd_info(prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
 SELECT prd_id,
 REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
 SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
 prd_nm,
 ISNULL(prd_cost,0) AS prd_cost,
 CASE UPPER(TRIM(prd_line))
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	ELSE 'n/a'
END AS prd_line,
CAST(prd_start_dt AS date) prd_start_dt,
CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)- 1 AS date) prd_end_dt
FROM bronze.crm_prd_info;


SELECT prd_id, COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

 SELECT *
 FROM silver.crm_prd_info
 WHERE prd_cost IS NULL;

 
 SELECT *
 FROM silver.crm_prd_info
 WHERE prd_cost < 0;

 SELECT *
 FROM silver.crm_prd_info
 WHERE prd_start_dt IS NULL;


 SELECT *
 FROM silver.crm_prd_info
 WHERE prd_end_dt IS NULL;

 SELECT *
 FROM silver.crm_prd_info
 WHERE prd_end_dt < prd_start_dt;

 -------------------------bronze.crm_sales_details-------------------------------

 SELECT TOP 10 *
 FROM bronze.crm_sales_details;

--Check for NULL or duplicate in Primary key

SELECT sls_ord_num, COUNT(*)
FROM bronze.crm_sales_details
GROUP BY sls_ord_num
HAVING COUNT(*) > 1 OR sls_ord_num IS NULL;

SELECT *
FROM bronze.crm_sales_details
WHERE sls_ord_num = 'SO55367'

----Check for unwanted spaces---

SELECT *
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

SELECT *
FROM bronze.crm_sales_details
WHERE sls_prd_key != TRIM(sls_prd_key);

--Data standardization and consistency--

 SELECT *
 FROM bronze.crm_sales_details
 WHERE sls_order_dt <= 0
 OR LEN(sls_order_dt) != 8
 OR sls_order_dt >= 20500101
 OR sls_order_dt <= 19000101;

 SELECT *
 FROM bronze.crm_sales_details
 WHERE sls_ship_dt <= 0
 OR LEN(sls_ship_dt) != 8
 OR sls_ship_dt >= 20500101
 OR sls_ship_dt <= 19000101;

 SELECT *
 FROM bronze.crm_sales_details
 WHERE sls_due_dt <= 0
 OR LEN(sls_due_dt) != 8
 OR sls_due_dt >= 20500101
 OR sls_due_dt <= 19000101;


 ---check for invalid order date--
 SELECT *
 FROM bronze.crm_sales_details
 WHERE  sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;
 
 ---check data consistency for qty,price,sales
 ---sales = qty * price
 --value must not be NULL,zero or neagtive

 SELECT *
 FROM bronze.crm_sales_details
 WHERE sls_sales != sls_quantity * sls_price 
 OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
 OR sls_sales <= 0 OR sls_quantity <=0 OR sls_price <=0


---TRANSFORMATION---

SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_order_dt AS varchar) AS date)
END AS sls_order_dt,
CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_ship_dt AS varchar) AS date)
END AS sls_ship_dt,
CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_due_dt AS varchar) AS date)
END AS sls_due_dt,
CASE WHEN sls_sales <=0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
          THEN sls_quantity * ABS(sls_price)
     ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price <=0 OR sls_price IS NULL
          THEN sls_sales/NULLIF(sls_quantity,0)
     ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;

INSERT INTO silver.crm_sales_details(sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,
sls_due_dt,sls_sales,sls_quantity,sls_price)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_order_dt AS varchar) AS date)
END AS sls_order_dt,
CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_ship_dt AS varchar) AS date)
END AS sls_ship_dt,
CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_due_dt AS varchar) AS date)
END AS sls_due_dt,
CASE WHEN sls_sales <=0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
          THEN sls_quantity * ABS(sls_price)
     ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price <=0 OR sls_price IS NULL
          THEN sls_sales/NULLIF(sls_quantity,0)
     ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;

SELECT *
FROM silver.crm_sales_details;


-------------------------bronze.erp_cust_az12-------------------------------

--Check for NULL or duplicate in Primary key

SELECT cid, COUNT(*)
FROM bronze.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;

SELECT *
FROM bronze.erp_cust_az12;


 --Data standardization and consistency--
SELECT DISTINCT gen
FROM bronze.erp_cust_az12;

SELECT *
FROM bronze.erp_cust_az12
WHERE cid != TRIM(cid);

SELECT DISTINCT bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > getdate();

-----------Transformation----
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4,LEN(gen))
	 ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
	 ELSE bdate
END AS bdate,
CASE WHEN  UPPER(TRIM(gen)) IN  ('M', 'MALE') THEN 'Male'
	 WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	 ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12;

INSERT INTO silver.erp_cust_az12(cid,bdate,gen)
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4,LEN(gen))
	 ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
	 ELSE bdate
END AS bdate,
CASE WHEN  UPPER(TRIM(gen)) IN  ('M', 'MALE') THEN 'Male'
	 WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	 ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12;

SELECT *
FROM SILVER.erp_cust_az12;

-------------------------bronze.erp_loc_a101-------------------------------

--Check for NULL or duplicate in Primary key

SELECT cid, COUNT(*)
FROM bronze.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;

SELECT *
FROM bronze.erp_loc_a101;

 --Data standardization and consistency--

SELECT DISTINCT cntry
FROM BRONZE.erp_loc_a101;

--Transformation---
SELECT REPLACE(cid,'-','') AS cid,
CASE WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
	 WHEN UPPER(TRIM(cntry)) IN ('DE','GERMANY') THEN 'Germany'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE cntry
END AS cntry
FROM bronze.erp_loc_a101;

INSERT INTO silver.erp_loc_a101(cid,cntry)
SELECT REPLACE(cid,'-','') AS cid,
CASE WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
	 WHEN UPPER(TRIM(cntry)) IN ('DE','GERMANY') THEN 'Germany'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE cntry
END AS cntry
FROM bronze.erp_loc_a101;

SELECT *
FROM silver.erp_loc_a101;


-------------------------bronze.erp_px_cat_g1v2-------------------------------

--Check for NULL or duplicate in Primary key

SELECT id, COUNT(*)
FROM bronze.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1 OR id IS NULL;

SELECT TOP 10 *
FROM bronze.erp_px_cat_g1v2;

SELECT *
FROM silver.crm_prd_info

 --Data standardization and consistency , unwanted spaces--

SELECT DISTINCT cat
FROM bronze.erp_px_cat_g1v2;
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE TRIM(cat) != cat;

SELECT DISTINCT subcat
FROM bronze.erp_px_cat_g1v2;
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE TRIM(subcat) != subcat;

SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2;


---Transformation---
INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
SELECT id,cat,subcat,maintenance
FROM bronze.erp_px_cat_g1v2;


SELECT *
FROM silver.erp_px_cat_g1v2;
