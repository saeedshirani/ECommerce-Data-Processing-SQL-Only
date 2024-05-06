-- Code Block 1: counting Duplicated rows in order_item Table
select order_id, count(order_id)
from order_items
group by order_id
ORDER BY count(order_id) DESC;

select *
from orders
where order_id == "ab14fdcfbe524636d65ee38360e22ce8";

select *
from order_items
where order_id == "8272b63d03f5f79c56e9e4120aec44ef";

select *
from order_reviews
where order_id == "ab14fdcfbe524636d65ee38360e22ce8";


-- Code Block 2: Recheck duplicates from Customers Table

select customer_unique_id, count(customer_unique_id) as num
from customers
group by customer_unique_id
order by num DESC;


select customer_id, count(customer_id) as num
from customers
group by customer_id
order by num DESC;

select *
from customers
where customer_unique_id == "8d50f5eadf50201ccdcedfb9e2ac8455";

-- Code Block 3: investigating Geolocation Table
select *
from geolocation;
-- Looking Clear

-- code Block 4: investigation in Order_payments Table
select order_id, count(order_id)
from order_payments
group by order_id
order by count(order_id) desc;

select *
from order_payments
where order_id == "df56136b8031ecd28e200bb18e6ddb2e";
select *
from order_items
where order_id == "df56136b8031ecd28e200bb18e6ddb2e";

-- code Block 5: investigation in Order_reviews Table
select *
from order_reviews;
select order_id, count(order_id)
from order_reviews
group by order_id
order by count(order_id) DESC;

select *
from order_reviews
where order_id == "c88b1d1b157a9999ce368f218a407141";

-- Customer Segmentation

-- Code Block 6: customer segmentation Based on Location
select orr.customer_id, cu.customer_city, count(orr.customer_id) as total_customers
from orders orr
         left join customers cu
                   on cu.customer_id = orr.customer_id
group by cu.customer_city
order by total_customers DESC;

-- code block 7: Customer Segmentation Based on payment method
SELECT orp.payment_type, count(orp.order_id) as total_orders
FROM order_payments orp
         left join orders orr
                   on orp.order_id = orr.order_id


GROUP BY orp.payment_type
order by total_orders DESC;

-- code block 8: Customer Segmentation Based on payment method and location
SELECT orp.payment_type,
       cu.customer_city,
       count(orp.order_id)          as total_orders,
       count(cu.customer_unique_id) as total_customers
FROM order_payments orp
         left join orders orr
                   on orp.order_id = orr.order_id

         left join customers cu
                   on orr.customer_id = cu.customer_id
GROUP BY orp.payment_type, cu.customer_city
order by total_orders DESC;


-- Code block 9 : Customers location vs product category
select pct.product_category_name_english, cu.customer_city, count(orr.order_id) as deal_per_location_category
from order_items orit
         left join products p
                   on p.product_id = orit.product_id
         left join product_category_name_translation pct
                   on pct.product_category_name = p.product_category_name
         left join orders orr
                   on orr.order_id = orit.order_id
         left join customers cu
                   on cu.customer_id = orr.customer_id
group by customer_city
order by deal_per_location_category DESC;

-- Code block 10 : Checking changes of seasonal sale for each city
SELECT season,
       year,
       customer_city,
       SUM(total_revenue)       AS total_revenue,
       SUM(total_freight_value) AS total_freight_value
FROM (SELECT CASE
                 WHEN strftime('%m', orr.order_purchase_timestamp) IN ('01', '02', '03') THEN 'Winter'
                 WHEN strftime('%m', orr.order_purchase_timestamp) IN ('04', '05', '06') THEN 'Spring'
                 WHEN strftime('%m', orr.order_purchase_timestamp) IN ('07', '08', '09') THEN 'Summer'
                 ELSE 'Fall'
                 END                                      AS season,
             strftime('%Y', orr.order_purchase_timestamp) AS year,
             cu.customer_city                             AS customer_city,
             orit.price                                   AS total_revenue,
             orit.freight_value                           AS total_freight_value
      FROM orders orr
               LEFT JOIN
           order_items orit ON orr.order_id = orit.order_id
               LEFT JOIN
           customers cu ON cu.customer_id = orr.customer_id)
GROUP BY season, year, customer_city
HAVING SUM(total_revenue) IS NOT NULL
ORDER BY year, season, customer_city;


--  code block 11 : segmentation based on times users did purchased
SELECT orr.order_purchase_timestamp as purchase_time,
       cu.customer_city,
       SUM(orit.price)              as total_revenue,
       SUM(orit.freight_value)      as total_freight_value
FROM orders orr
         LEFT JOIN order_items orit ON orr.order_id = orit.order_id
         LEFT JOIN customers cu ON cu.customer_id = orr.customer_id
GROUP BY orr.order_purchase_timestamp, cu.customer_city
HAVING SUM(orit.price) IS NOT NULL
ORDER BY purchase_time;

-- code block 12: for getting seasonal changes in each year regardless of location
SELECT season,
       year,
       round(SUM(total_revenue), 2)       AS total_revenue,
       round(SUM(total_freight_value), 2) AS total_freight_value
FROM (SELECT CASE
                 WHEN strftime('%m', orr.order_purchase_timestamp) IN ('01', '02', '03') THEN 'Winter'
                 WHEN strftime('%m', orr.order_purchase_timestamp) IN ('04', '05', '06') THEN 'Spring'
                 WHEN strftime('%m', orr.order_purchase_timestamp) IN ('07', '08', '09') THEN 'Summer'
                 ELSE 'Fall'
                 END                                      AS season,
             strftime('%Y', orr.order_purchase_timestamp) AS year,
             orit.price                                   AS total_revenue,
             orit.freight_value                           AS total_freight_value
      FROM orders orr
               LEFT JOIN
           order_items orit ON orr.order_id = orit.order_id
               LEFT JOIN
           customers cu ON cu.customer_id = orr.customer_id)
GROUP BY season, year
HAVING SUM(total_revenue) IS NOT NULL
ORDER BY year, season;

-- Sale Performance

-- code block 13 : total Sales and freight per category
SELECT COALESCE(pct.product_category_name_english, 'Unknown') as category,
       SUM(orit.price)                                        as total_sale,
       SUM(orit.freight_value)                                as total_freight

FROM order_items orit
         LEFT JOIN products pr
                   ON pr.product_id = orit.product_id
         LEFT JOIN product_category_name_translation pct
                   ON pct.product_category_name = pr.product_category_name
GROUP BY category;

-- for checking miss match
select *
from products
where product_id not in (select product_id
                         from order_items);
-- there is no miss match


-- code block 14 : total Sales and revenue per Seller
SELECT COALESCE(sl.seller_city, 'Unknown') as city,
       round(SUM(orit.price), 2)           as total_sale,
       round(SUM(orit.freight_value), 2)   as total_freight

FROM order_items orit
         LEFT JOIN sellers sl
                   ON sl.seller_id = orit.seller_id

GROUP BY city;


-- product analysis >> products based on total sales - total gained revenue -

-- code block 15 : top 50 most sold products
select product_id, count(product_id) as total_sales
from order_items
group by product_id
order by total_sales DESC
limit 50;

-- code block 16 : top 10 most gained revenue products in general
select orit.product_id,
       round(sum(orit.price), 2)         as revenue,
       round(sum(orit.freight_value), 2) as freight_price
from order_items orit
group by orit.product_id
order by revenue desc
limit 10;

-- code block 17: revenue per capita for each product
create view revenue_per_capita as
select orit.product_id,
       round(sum(orit.price), 2)                          as revenue,
       round(sum(orit.price) / count(orit.product_id), 2) as revenue_per_capita,
       round(orit.price, 2)                               as unit_price,
       round(sum(orit.freight_value), 2)                  as freight_price
from order_items orit
group by orit.product_id
order by revenue desc;


-- code block 18 : finding most beneficial products
-- (based on price -  freight value - warehousing cost consider by size of product)
select p.product_id,
       count(orit.product_id)                                                   as number_of_sales,
       orit.price                                                               as price,
       round(p.product_height_cm * p.product_length_cm * p.product_width_cm, 2) as size,
       p.product_weight_g                                                       as weight
from order_items orit
         join products p
              on p.product_id = orit.product_id
group by p.product_id
order by number_of_sales desc, price desc, size asc;


-- code block 19 : canceled products
select orr.order_status, orit.order_id, p.product_category_name, orit.seller_id
from order_items orit
         left join orders orr
                   on orr.order_id = orit.order_id
         left join products p
                   on orit.product_id = p.product_id
where orr.order_status == "canceled"
   or orr.order_status == "unavailable";

-- code block 20 :Infographic of order status
SELECT order_status                                             AS status,
       COUNT(order_id)                                          AS total_orders,
       (COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER ()) AS percentage
FROM orders
GROUP BY order_status;


-- code block 21 : Infographic of canceled products based on location and product category
select orr.order_status                                                 as Status,
       coalesce(p.product_category_name, "Unknown")                     as Category,
       coalesce(cu.customer_city, "Unknown")                            as location,
       (COUNT(orr.order_id) * 100.0 / SUM(COUNT(orr.order_id)) over ()) as percentage_per_category

from order_items orit
         left join orders orr
                   on orr.order_id = orit.order_id
         left join products p
                   on orit.product_id = p.product_id
         left join customers cu
                   on cu.customer_id = orr.customer_id
where orr.order_status == "canceled"
   or orr.order_status == "unavailable"
group by p.product_category_name, cu.customer_city;

-- code block 22 : Infographic of canceled products based on location
select orr.order_status                                                 as Status,
       coalesce(cu.customer_city, "Unknown")                            as location,
       (COUNT(orr.order_id) * 100.0 / SUM(COUNT(orr.order_id)) over ()) as percentage_per_category

from order_items orit
         left join orders orr
                   on orr.order_id = orit.order_id
         left join customers cu
                   on cu.customer_id = orr.customer_id
where orr.order_status == "canceled"
   or orr.order_status == "unavailable"
group by cu.customer_city;

-- code block 23 : Infographic of canceled products based on product category
select orr.order_status                                                 as Status,
       coalesce(p.product_category_name, "Unknown")                     as Category,
       (COUNT(orr.order_id) * 100.0 / SUM(COUNT(orr.order_id)) over ()) as percentage_per_category

from order_items orit
         left join orders orr
                   on orr.order_id = orit.order_id
         left join products p
                   on orit.product_id = p.product_id

where orr.order_status == "canceled"
   or orr.order_status == "unavailable"
group by p.product_category_name;


-- seller analysis

-- code block 24: rolling total of sellers Based on city, CTE table is included.
with seller_performance as (select sl.seller_id, round(sum(orit.price), 2) as total_outcome, sl.seller_city
                            from sellers sl
                                     left join order_items orit
                                               on sl.seller_id = orit.seller_id
                            group by sl.seller_id)

select seller_id,
       seller_city,
       total_outcome,
       sum(total_outcome) over (partition by seller_city order by seller_id) as Rolling_Total
from seller_performance;

-- code block 25: Average sellers outcome in each location
with seller_performance as (select sl.seller_id, round(sum(orit.price), 2) as total_outcome, sl.seller_city
                            from sellers sl
                                     left join order_items orit
                                               on sl.seller_id = orit.seller_id
                            group by sl.seller_id)

select seller_city, avg(total_outcome) average_revenue
from seller_performance
group by seller_city;

-- code block 26: geolocation performance of seller
select sl.seller_id,
       count(cu.customer_id) as         total_costumers,
       count(distinct (sl.seller_city)) cities,
       cu.customer_city,
       product_category_name
from orders ors
         left join order_items orit
                   on ors.order_id = orit.order_id
         left join sellers sl
                   on sl.seller_id = orit.seller_id
         left join customers cu
                   on ors.customer_id = cu.customer_id
         left join products p
                   on orit.product_id = p.product_id

where (sl.seller_id is not null)

group by sl.seller_id
having cities > 1;
-- output of this query is empty, so there is no intercity seller in this E-commerce.


-- Review analysis

-- code block 27: answering time monthly changes
select review_id,
       review_score,
       review_creation_date,
       review_answer_timestamp,
       (strftime('%s', review_answer_timestamp) - strftime('%s', review_creation_date)) /
       3600 as RA_time_diffrance_in_hour
from order_reviews;


-- use to know top windows function

-- code block 28_1: customer satisfaction monthly changes based on review score


select review_id,
       review_score,
       review_creation_date,
       review_answer_timestamp,
       (strftime('%s', review_answer_timestamp) - strftime('%s', review_creation_date)) /
       3600 as RA_time_diffrance_in_hour
from order_reviews;

DROP TABLE IF EXISTS order_review_timestamp;


CREATE TEMPORARY TABLE order_review_timestamp
(
    review_id                  VARCHAR(225),
    review_score               INT,
    review_creation_data       DATETIME,
    review_answer_timestamp    DATETIME,
    RA_time_difference_in_hour FLOAT
);

INSERT INTO order_review_timestamp (review_id, review_score, review_creation_data, review_answer_timestamp,
                                    RA_time_difference_in_hour)
SELECT review_id,
       review_score,
       review_creation_date,
       review_answer_timestamp,
       (strftime('%s', review_answer_timestamp) - strftime('%s', review_creation_date)) /
       3600 AS RA_time_difference_in_hour
FROM order_reviews;

-- code block 28_2:
with review_answer_detail as (select review_id,
                                     review_score,
                                     review_answer_timestamp,
                                     review_creation_data                    as review_creation_date,
                                     strftime('%Y', review_creation_data)    AS review_year,
                                     strftime('%m', review_creation_data)    AS review_Month,

                                     strftime('%Y', review_answer_timestamp) AS Answer_year,
                                     strftime('%m', review_answer_timestamp) AS Answer_Month,

                                     RA_time_difference_in_hour

                              from order_review_timestamp)

select review_year, review_month, round(avg(review_score), 2) as Average_score
from review_answer_detail
group by review_year, review_month;

-- code block 29: customer satisfaction Based on seller location( also good to say seller location == customer location)
select strftime('%Y', review_creation_data) AS review_year,
       strftime('%m', review_creation_data) AS review_Month,
       round(avg(ort.review_score), 2)      as average_review_score,
       cu.customer_city

from order_review_timestamp ort
         left join order_reviews orw
                   on ort.review_id = orw.review_id
         left join orders ors
                   on ors.order_id = orw.order_id
         left join customers cu
                   on cu.customer_id = ors.customer_id
group by customer_city
order by review_year, review_Month;

-- code block 30: customer satisfaction Based on payment method
select orpy.payment_type,
       round(avg(ort.review_score), 2) as average_review_score


from order_review_timestamp ort
         left join order_reviews orw
                   on ort.review_id = orw.review_id
         left join order_payments orpy
                   on orpy.order_id = orw.order_id
where payment_type is not null
group by orpy.payment_type;


-- code block 31.1: customer satisfaction Based on product category
select p.product_category_name              as category,
       strftime('%Y', review_creation_date) AS review_year,
       strftime('%m', review_creation_date) AS review_Month,
       round(avg(review_score), 2)          as average_review_score

from order_reviews orw
         left join order_items orit
                   on orit.order_id = orw.order_id
         left join products p
                   on p.product_id = orit.product_id
where product_category_name is not null
group by product_category_name, review_year, review_Month;


-- code block 31.2: another version
select p.product_category_name                 as category,
       strftime('%Y-%m', review_creation_date) AS review_date,
       round(avg(review_score), 2)             as average_review_score

from order_reviews orw
         left join order_items orit
                   on orit.order_id = orw.order_id
         left join products p
                   on p.product_id = orit.product_id
where product_category_name is not null
group by product_category_name, strftime('%Y', review_creation_date), strftime('%m', review_creation_date)

-- code block 32: customer satisfaction Based on product category - quarterly
select p.product_category_name              as category,
       (SELECT CASE
                   WHEN strftime('%m', review_creation_date) IN ('01', '02', '03') THEN 'Winter'
                   WHEN strftime('%m', review_creation_date) IN ('04', '05', '06') THEN 'Spring'
                   WHEN strftime('%m', review_creation_date) IN ('07', '08', '09') THEN 'Summer'
                   ELSE 'Fall'
                   END)                     AS season,
       strftime('%Y', review_creation_date) AS review_year,
       round(avg(review_score), 2)          as average_review_score

from order_reviews orw
         left join order_items orit
                   on orit.order_id = orw.order_id
         left join products p
                   on p.product_id = orit.product_id
where product_category_name is not null
group by product_category_name, review_year, season;

-- Logistic Analysis
-- code block 33:analysis of delivery lead time changes in monthly frame
select strftime('%Y-%m', order_purchase_timestamp) as date,
       cu.customer_city,
       round(avg((strftime('%s', order_delivered_customer_date) - strftime('%s', order_purchase_timestamp)) / 3600), 2)
                                                   as Delivery_lead_time,
       round(avg((strftime('%s', order_estimated_delivery_date) - strftime('%s', order_purchase_timestamp)) / 3600), 2)
                                                   as Estimated_Delivery_lead_time

from orders ors
         left join customers cu
                   on ors.customer_id = cu.customer_id

where order_delivered_customer_date is not null
group by date, cu.customer_city;

-- code block 34: analysis of purchase approval changes in monthly frame
select strftime('%Y-%m', order_purchase_timestamp) as date,

       round(avg((strftime('%s', order_approved_at) - strftime('%s', order_purchase_timestamp)) / 60), 2)
                                                   as approval_time_in_minute
from orders ors
where order_delivered_customer_date is not null
group by date;


-- code block 35: analysis of delivery carer date time changes in monthly frame (after approving order)
select strftime('%Y-%m', order_purchase_timestamp) as date,

       round(avg((strftime('%s', order_delivered_carrier_date) - strftime('%s', order_approved_at)) / 60), 2)
                                                   as Deliver_to_carrier_after_approval_mins
from orders ors
where order_delivered_customer_date is not null
group by date;



-- analysis of career to customer
select strftime('%Y-%m', order_purchase_timestamp) as date,

       round(avg((strftime('%s', order_delivered_customer_date) - strftime('%s', order_delivered_carrier_date)) / 60), 2)
                                                   as Deliver_to_carrier_after_approval_mins
from orders ors
where order_delivered_customer_date is not null
group by date;




