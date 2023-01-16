USE `gdb041`;

-- 1) Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT DISTINCT  market 
FROM dim_customer
WHERE customer = 'Atliq Exclusive' AND region LIKE '%APAC%';

/* The Market list is India,Indonesia,Japan,Philiphines,South Korea,Australia,Newzealand,Bangladesh 
which customer "Atliq Exclusive" operates its business in the APAC region. */

-- 2) What is the percentage of unique product increase in 2021 vs. 2020?
WITH  unique_product_count_2020a AS (
    SELECT count(DISTINCT product_code) AS unique_product_count_2020
    from fact_sales_monthly
    WHERE fiscal_year = 2020),
unique_product_count_2021a AS(
       SELECT count(DISTINCT product_code) AS unique_product_count_2021
    from fact_sales_monthly
    WHERE fiscal_year = 2021 )
SELECT 
       C.unique_product_count_2020, 
       B.unique_product_count_2021,
      round(((B.unique_product_count_2021-C.unique_product_count_2020)/C.unique_product_count_2020 * 100),2) as percentage_chg
FROM unique_product_count_2020a AS C
JOIN unique_product_count_2021a AS B;

/* Output
+-----------------------------+---------------------------+---------------------+
| 	unique_product_count_2020 |	unique_product_count_2021 |		percentage_chg  |	
+-----------------------------+---------------------------+---------------------+
|       245		              |	     334			      |			36.33	    |
+---------------+-------------------------------+-------------------------------+*/

-- 3) Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 

SELECT segment,count(distinct product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count desc;
/*
-- +------------------+------------------
|product_count      |   segment    		|
+------------------+--------------------+
|    129        	|	Notebook		|
|	 116			|	Accessories		|
|	 84			    |	 Peripherals	|
|    32		        |	Desktop		    |
|	 27			    |	Storage			|
|	  9			    |	Networking		|
+-------------------+-------------------+*/

/* 4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields, */

WITH  product_count_2020a AS (
    SELECT P.segment,count(DISTINCT P.product_code) AS product_count_2020
	FROM dim_product AS P
    INNER JOIN fact_sales_monthly AS Y
	ON p.product_code = Y.product_code
    WHERE fiscal_year = 2020 
    GROUP BY segment
    ORDER BY product_count_2020 desc),
product_count_2021a AS(
       SELECT P.segment,
	   count(DISTINCT P.product_code) AS product_count_2021
       FROM dim_product AS P
       INNER JOIN fact_sales_monthly AS Y
       ON p.product_code = Y.product_code
       WHERE fiscal_year = 2021 
       GROUP BY segment
       ORDER BY product_count_2021 desc)
SELECT B.segment,
       C.product_count_2020, 
       product_count_2021, 
       (B.product_count_2021 - C.product_count_2020 ) AS differnce
FROM product_count_2020a AS C
INNER JOIN product_count_2021a AS B
ON C.segment = B.segment;

/* Output
-- +------------------+------------------+--------------------+-----------------+
|      segment      | product_count_2020 | product_count_2021 |    differnce    |
+-------------------+--------------------+--------------------+-----------------+
|    Notebook     	|	      92         |      108           |      16         |
|	 Accessories	|	      69    	 |      103           |      34         |
|	 Peripherals	|	      59 	     |      075           |      16         |
|    Desktop		|	      12		 |      017           |      05         |
|	 Storage		|	      07		 |      022           |      15         |
|	 Networking		|	      06		 |      009           |      03         |
+-------------------+-------------------+--------------------+-----------------+*/

-- 5. Get the products that have the highest and lowest manufacturing costs.
  
SELECT P.product,
       P.product_code,
       round(M.manufacturing_cost,2) AS Manufacturing_cost
FROM dim_product AS P
INNER JOIN fact_manufacturing_cost AS M
ON P.product_code = M.product_code
WHERE manufacturing_cost = (SELECT max(manufacturing_cost) FROM fact_manufacturing_cost)
UNION
SELECT P.product,
       P.product_code,
       round(M.manufacturing_cost,2) AS Manufacturing_cost
FROM dim_product AS P
INNER JOIN fact_manufacturing_cost AS M
ON P.product_code = M.product_code
WHERE manufacturing_cost = (SELECT min(manufacturing_cost) FROM fact_manufacturing_cost);

/* Output
+-----------------------------+---------------------------+-------------------------+
| 	product                   |	       product_code       |		Manufacturing_cost  |	
+-----------------------------+---------------------------+-------------------------+
|    AQ HOME Allin1 Gen 2	  |	    A6120110206           |			240.54	        |
|  AQ Master wired x1 Ms      |     A2118150101           |          0.89           |
+---------------+-------------------------------+-----------------------------------+*/

/*6) Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market */

SELECT C.customer_code,
       customer,
       pre_invoice_discount_pct
FROM dim_customer AS C
INNER JOIN fact_pre_invoice_deductions AS F
ON C.customer_code = F.customer_code 
WHERE fiscal_year = 2021 AND market = 'India'
AND F.pre_invoice_discount_pct > (SELECT AVG(pre_invoice_discount_pct) FROM fact_pre_invoice_deductions)
ORDER BY pre_invoice_discount_pct desc
LIMIT 5;

/*
7)Get the complete report of the Gross sales amount for the customer “Atliq
  Exclusive” for each month. This analysis helps to get an idea of low and
  high-performing months and take strategic decision */

SELECT MONTH(date) as Month, 
       YEAR(date) as Year,
       sum(F.gross_price * M.sold_quantity) AS Gross_sales_Amount
FROM fact_sales_monthly AS M
INNER JOIN fact_gross_price AS F
ON F.product_code = M.product_code
INNER JOIN dim_customer AS C
ON C.customer_code = M.customer_code
WHERE customer = 'Atliq Exclusive'
GROUP BY MONTH(date),YEAR(date)
ORDER BY YEAR(date);

/*
+-------+------+--------------------+
| Month | Year | Gross_sales_Amount |
+-------+------+--------------------+
| 9	    | 2019 |	9092670.339     |
| 10	| 2019 |    10378637.6      |
| 11	| 2019 |	15231894.97     |
| 12	| 2019 |	9755795.058     |
|  1	| 2020 |    9584951.939     |
|  2	| 2020 |    8083995.548     |
|  3	| 2020 |	766976.4531     |
|  4	| 2020 |	800071.9543     |
|  5	| 2020 |	1586964.477     |
|  6	| 2020 |	3429736.571     |
|  7	| 2020 | 	5151815.402     |
|  8	| 2020 |	5638281.829     |
|  9	| 2020 |    19530271.3      |
| 10	| 2020 |	21016218.21     |
| 11	| 2020 |	32247289.79     |
| 12	| 2020 |	20409063.18     |
|  1	| 2021 |	19570701.71     |
|  2	| 2021 |	15986603.89     |
|  3	| 2021 | 	19149624.92     |
|  4	| 2021 |    11483530.3      |
|  5	| 2021 |    19204309.41     |
|  6	| 2021 |    15457579.66     |
|  7	| 2021 |    19044968.82     |
|  8	| 2021 |	11324548.34     |
+-----+--------+--------------------+
*/

/* 8) In which quarter of 2020, got the maximum total_sold_quantity?  */

SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then 1 
    WHEN date between '2019-12-01' AND '2020-02-01' then 2
    WHEN date between '2020-03-01' AND '2020-05-01' then 3
    WHEN date between '2020-06-01' AND '2020-08-01' then 4
    END AS Quarter,
    sum(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity desc
LIMIT 1;

/* Output
+---------------------------------------+
| 	Quarter     |	total_sold_quantity |
+---------------------------------------+
|       1	    |	     7005619		|
+---------------+-----------------------+
*/


/* 9) Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? */

WITH sales AS(
SELECT channel,
       round(sum(G.gross_price * M.sold_quantity),2) AS gross_sales_mln
FROM dim_customer AS C
INNER JOIN fact_sales_monthly AS M
ON C.customer_code = M.customer_code
INNER JOIN fact_gross_price AS G
ON G.product_code = M.product_code
GROUP BY channel
ORDER BY gross_sales_mln desc)
SELECT channel,
       gross_sales_mln,
       (round(S.gross_sales_mln/t.total *100)) AS Percentage
FROM sales AS S
CROSS JOIN (SELECT sum(gross_sales_mln) AS total FROM sales) t;

/* OUTPUT  
+--------------------+------------------------+-----------------+
| 	CHANNEL          |	  gross_sales_mln     |		Percentage  |	
+--------------------+------------------------+-----------------+
|    Retailer	     |	 2690556298.96        |			72	    |
|    Direct          |   601710533.77         |         16      |
|   Distributor      |   419449097.61         |         11      |
+---------------+-------------------------------+---------------+ */

/* 10) Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?  */

WITH sales AS (
SELECT division,
	   M.product_code,product,
	   sum(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly AS M
LEFT JOIN  dim_product AS P
ON M.product_code = P.product_code
WHERE fiscal_year = 2021
GROUP BY M.product_code, division,product),
rank_ov AS(
SELECT product_code,
       total_sold_quantity,
	   DENSE_RANK () OVER(PARTITION BY division ORDER BY total_sold_quantity desc) AS Rank_order
FROM sales AS S)
SELECT division,
       S.product_code, 
       product ,
       S.total_sold_quantity, 
       Rank_order
FROM sales AS S
INNER JOIN rank_ov AS R
ON R.product_code = S.product_code
WHERE Rank_order BETWEEN 1 AND 3;


/* Output
+----------+---------------------------------------------------------------------------------------+ 
| division |     product_code    |        product	        |   total_sold_quantity   |	Rank_order |
---------- +---------------------+--------------------------+-------------------------+------------+
| N & S	   |    A6720160103	     |  AQ Pen Drive 2 IN 1	    |        701373	          |    1       |
| N & S    | 	A6818160202	     |   AQ Pen Drive DRC	    |        688003	          |    2       |
| N & S	   |    A6819160203      |	 AQ Pen Drive DRC	    |        676245	          |    3       |
+----------+---------------------+--------------------------+-------------------------+------------+
| P & A	   |    A2319150302	     |     AQ Gamers Ms	        |        428498	          |    1       |
| P & A	   |    A2520150501	     |     AQ Maxima Ms	        |        419865           |    2       |
| P & A	   |    A2520150504	     |     AQ Maxima Ms	        |        419471	          |    3       |
+----------+---------------------+--------------------------+-------------------------+------------+
| PC	   |    A4218110202	     |       AQ Digit	        |        17434	          |    1       |
| PC	   |    A4319110306      |     AQ Velocity	        |        17280	          |    2       |
| PC	   |    A4218110208	     |       AQ Digit	        |        17275	          |    3       |
+----------+---------------------+--------------------------+-------------------------+------------+
 */

