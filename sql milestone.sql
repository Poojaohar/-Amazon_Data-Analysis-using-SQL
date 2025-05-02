select * from amazon_brazil.orders
select * from amazon_brazil.payments

------------------------------------------------------------Analysis - I-------------------------------------------------------------------------------

Q1----To simplify its financial reports, Amazon India needs to standardize payment values. 
----Round the average payment values to integer (no decimal) for each payment type and display the results sorted in ascending order

select payment_type, 
       ROUND(avg(payment_value)) as rounded_avg_payment 
from amazon_brazil.payments 
group by payment_type 
order by rounded_avg_payment asc;


Q2---To refine its payment strategy, Amazon India wants to know the distribution of orders by payment type.
----- Calculate the percentage of total orders for each payment type, rounded to one decimal place, and display them in descending order
Select
    p.payment_type, 
    ROUND((count(o.order_id) * 100.0) / (select count(*) from amazon_brazil.orders), 1) as percentage_orders
from amazon_brazil.orders as o
join amazon_brazil.payments p ON o.order_id = p.order_id
group by p.payment_type
order BY percentage_orders DESC;



Q3---Amazon India seeks to create targeted promotions for products within specific price ranges.
-- Identify all products priced between 100 and 500 BRL that contain the word 'Smart' in their name. 
-----Display these products, sorted by price in descending order.
--Output: product_id, price



select p.product_id, o.price
from amazon_brazil.products as p
left join amazon_brazil.order_items AS o ON p.product_id = o.product_id
left join amazon_brazil.payments AS py ON o.order_id = py.order_id
where o.price BETWEEN 100 AND 500
and p.product_category_name ILIKE '%Smart%'
order by o.price DESC;

Q4----To identify seasonal sales patterns, Amazon India needs to focus on the most successful months. 
----Determine the top 3 months with the highest total sales value, rounded to the nearest integer.
---Output: month, total_sales

select extract(month from o.order_purchase_timestamp) as month,  
       ROUND(sum(pr.price)) as total_sales  
from amazon_brazil.orders as o  
 left JOIN amazon_brazil.order_items AS pr ON o.order_id = pr.order_id  
group by extract(month from o.order_purchase_timestamp)  
order by  total_sales DESC  
limit 3;
Q5----Amazon India is interested in product categories with significant price variations. 
-----Find categories where the difference between the maximum and minimum product prices is greater than 500 BRL.
---Output: product_category_name, price_difference

select * from amazon_brazil.products
select *  from amazon_brazil.order_items



select p.product_category_name,  
       (max(o.price) - min(o.price)) ass price_difference  
from amazon_brazil.products as p  
left join amazon_brazil.order_items as o  
on p.product_id = o.product_id  
group by p.product_category_name  
having (max(o.price) - min(o.price)) > 500  
order by  price_difference desc;



Q6--To enhance the customer experience, Amazon India wants to find which payment types have the most consistent transaction amounts.
----- Identify the payment types with the least variance in transaction amounts, sorting by the smallest standard deviation first.
--Output: payment_type, std_deviation

select * from amazon_brazil.payments

select payment_type,  
       STDDEV(payment_value) ass std_deviation  
from amazon_brazil.payments  
group by payment_type  
order by std_deviation asc;

Q7----Amazon India wants to identify products that may have incomplete name in order to fix it from their end.
----Retrieve the list of products where the product category name is missing or contains only a single character.
---Output: product_id, product_category_name
select * from amazon_brazil.products

select  product_id, product_category_name  
from amazon_brazil.products  
where product_category_name is null   
      or trim(product_category_name) = ''  
      or length(product_category_name) = 1;
	  
	  

-----------------------------------------------------------------Analysis - II------------------------------------------------------------------------------------------


Q1----Amazon India wants to understand which payment types are most popular across different order value segments (e.g., low, medium, high). 
-----Segment order values into three ranges: orders less than 200 BRL, between 200 and 1000 BRL, and over 1000 BRL. 
---Calculate the count of each payment type within these ranges and display the results in descending order of count
---Output: order_value_segment, payment_type, count


select * from amazon_brazil.payments
select
    case  
        when payment_value < 200 then 'Low'  
        when payment_value between 200 and 1000 then 'Medium'  
        else 'High'  
    end as order_value_segment,  
    payment_type,  
    count(*) as count  
from amazon_brazil.payments  
group by   
    case  
        when payment_value < 200 then 'Low'  
        when payment_value between 200 AND 1000 THEN 'Medium'  
        ELSE 'High'  
    END,  
    payment_type  
ORDER By count DESC;


Q2----Amazon India wants to analyse the price range and average price for each product category. 
-----Calculate the minimum, maximum, and average price for each category, and list them in descending order by the average price.
---Output: product_category_name, min_price, max_price, 


select 
    p.product_category_name,  
    min(o.price) as min_price,  
    max(o.price) as max_price,  
    ROUND(avg(o.price), 2) as avg_price  
from amazon_brazil.order_items as o  
join amazon_brazil.products as p  
on o.product_id = p.product_id  
group by p.product_category_name  
order by avg_price desc;



 



Q3---- Amazon India wants to identify the customers who have placed multiple orders over time. 
----Find all customers with more than one order, and display their customer unique IDs along with the total number of orders they have placed.
--Output: customer_unique_id, total_orders

select *  from amazon_brazil.customers
select * from amazon_brazil.orders

 select 
    c.customer_unique_id, 
    count(o.order_id) as total_orders
   from amazon_brazil.customers as  c
left join amazon_brazil.orders AS o 
on c.customer_id = o.customer_id
group by c.customer_unique_id
having count(o.order_id) > 1
order by total_orders desc;



Q4--Amazon India wants to categorize customers into different types
--- ('New – order qty. = 1' ;  'Returning' –order qty. 2 to 4;  'Loyal' – order qty. >4) 
---based on their purchase history. Use a temporary table to define these categories and join it with the customers table to update 
--and display the customer types.
select
    c.customer_id, 
    count(o.order_id) over (partition by  c.customer_id) as total_orders,
    case  
  when count(o.order_id) over (partition  by c.customer_id) = 1 then 'New'  
  when count(o.order_id) over (partition by c.customer_id) between 2 and  4 then  'Returning' 
   else'Loyal'  
    end as  customer_type  
from amazon_brazil.orders AS o
 join amazon_brazil.customers AS c 
on o.customer_id = c.customer_id
group by  c.customer_id, o.order_id
order by  total_orders DESC;





Q5---Amazon India wants to know which product categories generate the most revenue. 
---Use joins between the tables to calculate the total revenue for each product category. Display the top 5 categories.
----Output: product_category_name, total_revenue

----i have used three tables here because the Payments table doesn't have product_id, so we need order_items as a link.
 ---Order items connect payments to products, allowing us to categorize revenue by product type.

select * from amazon_brazil.products
select *  from amazon_brazil.order_items
select * from amazon_brazil.payments

  select p.product_category_name,  
       ROUND(sum(py.payment_value)) as total_revenue  
from amazon_brazil.products as p  
join amazon_brazil.order_items as oi on  p.product_id = oi.product_id  
join amazon_brazil.payments as py on oi.order_id = py.order_id  
group by p.product_category_name  
order by total_revenue DESC  
limit 5;






-----------------------------------------------------------Analysis - III------------------------------------------------------------------------
Q1---The marketing team wants to compare the total sales between different seasons. 
-----Use a subquery to calculate total sales for each season (Spring, Summer, Autumn, Winter) based on order purchase dates, 
-----and display the results. Spring is in the months of March, April and May. Summer is from June to June and Autumn is between September 
-----and November and rest months are Winter. 
----Output: season, total_sales


select * from amazon_brazil.payments
select *  from amazon_brazil.orders



select season, total_sales
from (
    select  
        case  
            when extract(month from o.order_purchase_timestamp) in (3,4,5) then 'Spring'  
            when extract(month from o.order_purchase_timestamp) in (6,7,8) then 'Summer'  
            when extract(month from o.order_purchase_timestamp) in (9,10,11) then 'Autumn'  
            else 'Winter'  
        end as season,  
        sum(py.payment_value) as total_sales  
    from amazon_brazil.orders as o  
    join amazon_brazil.payments as py  
    on o.order_id = py.order_id  
    group by season  
) as seasonal_sales
order by  total_sales DESC;


Q2--The inventory team is interested in identifying products that have sales volumes above the overall average.
--Write a query that uses a subquery to filter products with a total quantity sold above the average quantity.
--Output: product_id, total_quantity_sold


select * from amazon_brazil.products
select *  from amazon_brazil.order_items

SELECT o.product_id, SUM(o.order_item_id) AS total_quantity_sold
FROM amazon_brazil.order_items AS o
GROUP BY o.product_id
HAVING SUM(o.order_item_id) > (
   
    SELECT AVG(total_quantity) 
    FROM (
        SELECT product_id, SUM(order_item_id) AS total_quantity
        FROM amazon_brazil.order_items
        GROUP BY product_id
    ) AS avg_sales
)ORDER BY total_quantity_sold DESC;



----Q3To understand seasonal sales patterns, the finance team is analysing the monthly revenue trends over the past year (year 2018). 
---Run a query to calculate total revenue generated each month and identify periods of peak and low sales. Export the data to Excel and create a graph to visually represent revenue changes across the months. 

---Output: month, total_revenue


select 
    extract(month from o.order_purchase_timestamp) as month,  
    sum(
        (select sum(p.payment_value) 
         from amazon_brazil.payments p 
         where p.order_id = o.order_id)
    ) as total_revenue  
from amazon_brazil.orders o  
where extract(year from o.order_purchase_timestamp) = 2018  
group by month  
order by month;

Q4--A loyalty program is being designed  for Amazon India. 
---Create a segmentation based on purchase frequency: ‘Occasional’ for customers with 1-2 orders, ‘Regular’ for 3-5 orders, and ‘Loyal’ for more than 5 orders. 
---Use a CTE to classify customers and their count and generate a chart in Excel to show the proportion of each segment.
--Output: customer_type, count
select *from amazon_brazil.orders
select *  from amazon_brazil.customers

with customer_type as (
    select
        count(o.order_id) AS total_orders,
        case 
        when count(o.order_id) between 1 and 2 then 'Occasional'
        when count(o.order_id) between 3 and 5 then 'Regular'
            else 'Loyal'
        end as customer_type
    from amazon_brazil.orders as o
    join amazon_brazil.customers as c 
    on o.customer_id = c.customer_id
    group by c.customer_id
)
select  customer_type, count(*) as customer_count
FROM customer_type
group by customer_type
order by customer_count DESC;

------------------------------------------------------------------------------------------------------------------------------------------------------
Q5---Amazon wants to identify high-value customers to target for an exclusive rewards program. 
----You are required to rank customers based on their average order value (avg_order_value) to find the top 20 customers.
--Output: customer_id, avg_order_value, and customer_rank

select *from amazon_brazil.payments
select *  from amazon_brazil.orders


with customer_rank as (
    select
        o.customer_id, 
         round (avg(p.payment_value),1)as avg_order_value,
        rank() over (order by  avg(p.payment_value) desc) aS customer_rank
    from amazon_brazil.orders as o
    join amazon_brazil.payments as p 
    on o.order_id = p.order_id
    group by o.customer_id
)
select customer_id, avg_order_value, customer_rank
from customer_rank
order by customer_rank 
limit 20;



Q6--Amazon wants to analyze sales growth trends for its key products over their lifecycle.
--Calculate monthly cumulative sales for each product from the date of its first sale. 
--Use a recursive CTE to compute the cumulative sales (total_sales) for each product month by month.
--Output: product_id, sale_month, and total_sale

SELECT* FROM amazon_brazil.products    
SELECT* FROM om amazon_brazil.orders
SELECT* FROM  amazon_brazil.payments
SELECT* FROM  amazon_brazil.order_itmes

with product_sales as (
    select
        pr.product_id,
        extract(year from o.order_purchase_timestamp) as sale_year,
        extract(month from o.order_purchase_timestamp) as sale_month,
        sum(p.payment_value) as monthly_sales
    from amazon_brazil.orders as o
    join amazon_brazil.order_items as oi on o.order_id = oi.order_id
   join amazon_brazil.products as pr on oi.product_id = pr.product_id
    join amazon_brazil.payments as p on o.order_id = p.order_id
   group by pr.product_id, sale_year, sale_month
)

select
    product_id,
    sale_year,
    sale_month,
    sum(monthly_sales) over (partition by product_id order by  sale_year, sale_month) as total_sales
from product_sales
order by product_id, sale_year, sale_month;


Q7---To understand how different payment methods affect monthly sales growth, Amazon wants to compute the total sales for each payment method and 
----calculate the month-over-month growth rate for the past year (year 2018). 
----Write query to first calculate total monthly sales for each payment method, then compute the percentage change from the previous month.
--Output: payment_type, sale_month, monthly_total, monthly_change.

select *from amazon_brazil.payments
select *from amazon_brazil.orders

WITH monthly_sales AS (
    SELECT
        py.payment_type,
        EXTRACT(month FROM o.order_purchase_timestamp) AS sale_month,
        ROUND(SUM(py.payment_value), 2) AS monthly_total
    FROM amazon_brazil.payments AS py
    JOIN amazon_brazil.orders AS o 
    ON py.order_id = o.order_id
    WHERE EXTRACT(year FROM o.order_purchase_timestamp) = 2018
    GROUP BY py.payment_type, sale_month
),
growth_calc AS (
    SELECT 
        payment_type,
        sale_month,
        monthly_total,
        LAG(monthly_total) OVER (PARTITION BY payment_type ORDER BY sale_month) AS prev_month_sales
    FROM monthly_sales
)
SELECT 
    payment_type,
    sale_month,
    monthly_total,
    CASE 
        WHEN prev_month_sales IS NULL THEN '-' 
        ELSE ROUND(((monthly_total - prev_month_sales) / NULLIF(prev_month_sales, 0)) * 100, 2) || '%' 
    END AS monthly_change
FROM growth_calc
ORDER BY payment_type, sale_month;





   
