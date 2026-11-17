USE magist;

# =============================================================================
# Should Eniac sell premium tech on Magist?
# Market entry analysis on the Magist database (MySQL 8)
# Author: Samer Odeh. Started as a WBS Coding School case study.
#
# Definitions used in every query:
#   Tech         = the 10 categories: computers, computers_accessories,
#                  electronics, telephony, fixed_telephony, audio,
#                  consoles_games, pc_gamer, tablets_printing_image, cine_photo
#   Premium tech = a tech item with price above 500
#   Prices are per item (order_items.price), not per order.
#   Delivery numbers use delivered orders only.
#   On time      = DATE(delivered) <= DATE(estimated). The estimated date is
#                  stored at 00:00, so comparing full timestamps would count
#                  a parcel delivered on the promised afternoon as late.
#   Sept and Oct 2018 have only 20 orders, so monthly trends stop at Aug 2018.
# =============================================================================


# -----------------------------------------------------------------------------
# 1. SCOPE
# -----------------------------------------------------------------------------

#How many orders are there, and over what period?
	#99,441 orders, 2016-09-04 to 2018-10-17, 25 months
SELECT COUNT(*) AS total_orders,
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order,
    COUNT(DISTINCT DATE_FORMAT(order_purchase_timestamp, '%Y-%m')) AS total_months
FROM orders;

#Are orders actually delivered?
	#Yes, 97.02% delivered
SELECT order_status, COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

#What are the highest and lowest payment values?
	#The lowest is 0 because of 9 voucher / not_defined payments, so they are excluded
	#Max about 13,664, min (without the 0 payments) 0.01
SELECT COUNT(*) AS zero_payments FROM order_payments WHERE payment_value = 0;
SELECT payment_type, COUNT(*) AS zero_payments FROM order_payments WHERE payment_value = 0 GROUP BY payment_type;
SELECT ROUND(MAX(payment_value), 2) AS max_payment, ROUND(MIN(payment_value), 2) AS min_payment
FROM order_payments
WHERE payment_value > 0;


# -----------------------------------------------------------------------------
# 2. DEMAND: is Magist growing?
# -----------------------------------------------------------------------------

#Orders per month
	#Strong growth in 2017, peak Nov 2017 with 7,544 orders (Black Friday)
	#Flat in 2018: between 6,167 and 7,269 orders a month (Jan to Aug)
SELECT YEAR(order_purchase_timestamp) AS Year, MONTH(order_purchase_timestamp) AS Month, COUNT(*) AS orders_total
FROM orders
WHERE order_purchase_timestamp < '2018-09-01'
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
ORDER BY Year, Month;


# -----------------------------------------------------------------------------
# 3. FIT: how much of Magist is tech?
# -----------------------------------------------------------------------------

#Tech share of the catalogue
	#11.69% of all products are tech
SELECT
    ROUND(COUNT(DISTINCT CASE WHEN pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
        THEN p.product_id END) * 100.0 / COUNT(DISTINCT p.product_id), 2) AS tech_share_of_catalogue
FROM products p
LEFT JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name;

#Tech share of items sold
	#15.33% of all items sold are tech
SELECT
CASE WHEN pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
THEN 'tech-products' ELSE 'other-products' END AS product_type,
COUNT(*) AS products_sold,
ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM order_items), 2) AS percentage_sales
FROM order_items o
LEFT JOIN products p ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
GROUP BY product_type;

#Tech share of revenue
	#14.00% of item revenue is tech
SELECT
    ROUND(SUM(CASE WHEN pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
        THEN o.price ELSE 0 END) * 100 / SUM(o.price), 2) AS tech_share_of_revenue
FROM order_items o
LEFT JOIN products p ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name;

#Which tech categories sell?
	#Mostly cheap accessories: computers_accessories 45.3%, telephony 26.3%, electronics 16.0%
	#Computers are only 1.2% of tech items, but almost all of them cost more than 500
SELECT
    pc.product_category_name_english AS category,
    COUNT(*) AS products_sold,
    ROUND(COUNT(*) * 100 / 17271, 1) AS pct_of_tech_items,  # 17,271 = all tech items sold (query above)
    ROUND(AVG(o.price), 2) AS average_price,
    ROUND(SUM(o.price)) AS total_revenue,
    SUM(CASE WHEN o.price > 500 THEN 1 ELSE 0 END) AS items_above_500
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
GROUP BY pc.product_category_name_english
ORDER BY products_sold DESC;


# -----------------------------------------------------------------------------
# 4. PRICE: is there a premium market?
# -----------------------------------------------------------------------------

#Average price of items sold, calculated instead of typed in
	#120.65 per item, 28.52% of items are above it
SELECT ROUND(AVG(price), 2) AS average_price FROM order_items;
SELECT
CASE WHEN price > (SELECT AVG(price) FROM order_items) THEN 'above average price' ELSE 'average or below' END AS price_avg,
COUNT(*) AS items,
ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM order_items), 2) AS percentage
FROM order_items
GROUP BY price_avg;

#Average price of tech items
	#110.16, cheaper than the marketplace average
SELECT ROUND(AVG(o.price), 2) AS average_tech_price
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo');

#Tech items by price band
	#51.5% of tech items cost 50 or less, only 3.28% cost more than 500
SELECT
    CASE
        WHEN o.price <= 50 THEN '1. up to 50'
        WHEN o.price <= 100 THEN '2. 50-100'
        WHEN o.price <= 200 THEN '3. 100-200'
        WHEN o.price <= 500 THEN '4. 200-500'
        WHEN o.price <= 1000 THEN '5. 500-1000'
        ELSE '6. over 1000'
    END AS price_band,
    COUNT(*) AS items_sold,
    ROUND(COUNT(*) * 100 / 17271, 2) AS pct_of_tech_items,
    ROUND(SUM(o.price)) AS revenue
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
GROUP BY price_band
ORDER BY price_band;

#Premium tech in total
	#567 items, 574,728 revenue, 91 sellers, average price 1,013.63
	#567 / 25 months = about 23 a month
SELECT
    COUNT(*) AS premium_items,
    ROUND(SUM(o.price)) AS premium_revenue,
    COUNT(DISTINCT o.seller_id) AS premium_sellers,
    ROUND(AVG(o.price), 2) AS average_premium_price
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
AND o.price > 500;

#Premium tech per month
	#Black Friday (Nov 2017) sold only 25 premium tech items
SELECT YEAR(ord.order_purchase_timestamp) AS Year, MONTH(ord.order_purchase_timestamp) AS Month,
    COUNT(*) AS premium_items, ROUND(SUM(o.price)) AS premium_revenue
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
JOIN orders ord ON o.order_id = ord.order_id
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
AND o.price > 500
AND ord.order_purchase_timestamp < '2018-09-01'
GROUP BY YEAR(ord.order_purchase_timestamp), MONTH(ord.order_purchase_timestamp)
ORDER BY Year, Month;

#Premium tech in 2018 (Jan to Aug = 8 months): today's market size
	#283 items, about 35 a month, about 31,900 revenue a month
SELECT
    COUNT(*) AS premium_items_2018,
    ROUND(COUNT(*) / 8, 1) AS items_per_month,
    ROUND(SUM(o.price) / 8) AS revenue_per_month
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
JOIN orders ord ON o.order_id = ord.order_id
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
AND o.price > 500
AND ord.order_purchase_timestamp >= '2018-01-01'
AND ord.order_purchase_timestamp < '2018-09-01';

#Who sells premium tech? Top 10 sellers
	#One seller has 153 of 567 premium items (27%). The top 3 have about 40%.
SELECT
    o.seller_id,
    COUNT(*) AS premium_items,
    ROUND(COUNT(*) * 100 / 567, 1) AS pct_of_premium_items,  # 567 = all premium tech items
    ROUND(SUM(o.price)) AS premium_revenue
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
AND o.price > 500
GROUP BY o.seller_id
ORDER BY premium_items DESC
LIMIT 10;


# -----------------------------------------------------------------------------
# 5. DELIVERY: can Magist deliver a premium promise?
# -----------------------------------------------------------------------------

#Promised vs actual delivery days
	#Promised 24.4 days, actual 12.5 days
SELECT
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(order_estimated_delivery_date, order_purchase_timestamp)), 1) AS avg_promised_days,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_actual_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

#Delivery on time (delivered orders only)
	#Fix: the first version divided by ALL orders, which gave 89%
	#93.2% on time
SELECT
    CASE
        WHEN DATE(order_delivered_customer_date) <= DATE(order_estimated_delivery_date) THEN 'On time'
        ELSE 'Late'
    END AS delivery_on_time,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders WHERE order_delivered_customer_date IS NOT NULL), 2) AS percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY delivery_on_time;

#On time by year
	#2017: 94.4%, 2018: 92.3%. Getting worse.
SELECT
    YEAR(order_purchase_timestamp) AS Year,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(CASE WHEN DATE(order_delivered_customer_date) <= DATE(order_estimated_delivery_date) THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_on_time
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY Year;

#Delivery by segment: premium tech orders vs other tech vs non-tech
	#An order is "premium tech" if it has at least one premium tech item
	#Premium tech: 15.5 days, 91.5% on time, only 61.1% arrive within 14 days
	#Non-tech: 12.4 days, 93.2% on time, 71.8% within 14 days
SELECT
    CASE
        WHEN ord.order_id IN (SELECT o.order_id FROM order_items o
                              JOIN products p ON o.product_id = p.product_id
                              JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
                              WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
                              AND o.price > 500) THEN 'premium tech'
        WHEN ord.order_id IN (SELECT o.order_id FROM order_items o
                              JOIN products p ON o.product_id = p.product_id
                              JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
                              WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')) THEN 'other tech'
        ELSE 'non-tech'
    END AS segment,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(ord.order_estimated_delivery_date, ord.order_purchase_timestamp)), 1) AS avg_promised_days,
    ROUND(AVG(DATEDIFF(ord.order_delivered_customer_date, ord.order_purchase_timestamp)), 1) AS avg_actual_days,
    ROUND(SUM(CASE WHEN DATE(ord.order_delivered_customer_date) <= DATE(ord.order_estimated_delivery_date) THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_on_time,
    ROUND(SUM(CASE WHEN DATEDIFF(ord.order_delivered_customer_date, ord.order_purchase_timestamp) <= 14 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_within_14_days
FROM orders ord
WHERE ord.order_delivered_customer_date IS NOT NULL
GROUP BY segment
ORDER BY segment DESC;

#What a late delivery does to the review score
	#On time: about 4.2 stars. Late: about 2.2 stars, in every segment.
	#64% of late premium tech orders get 1 or 2 stars.
SELECT
    CASE
        WHEN ord.order_id IN (SELECT o.order_id FROM order_items o
                              JOIN products p ON o.product_id = p.product_id
                              JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
                              WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
                              AND o.price > 500) THEN 'premium tech'
        WHEN ord.order_id IN (SELECT o.order_id FROM order_items o
                              JOIN products p ON o.product_id = p.product_id
                              JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
                              WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')) THEN 'other tech'
        ELSE 'non-tech'
    END AS segment,
    CASE WHEN DATE(ord.order_delivered_customer_date) <= DATE(ord.order_estimated_delivery_date) THEN 'on time' ELSE 'late' END AS delivery,
    COUNT(*) AS reviews,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_1_or_2_stars
FROM orders ord
JOIN order_reviews r ON ord.order_id = r.order_id
WHERE ord.order_delivered_customer_date IS NOT NULL
GROUP BY segment, delivery
ORDER BY segment DESC, delivery DESC;

#North vs Sao Paulo
	#North = AC, AP, AM, PA, RO, RR, TO
	#North 22.5 days, Sao Paulo 8.7 days = 2.6 times as long
SELECT
    CASE
        WHEN g.state IN ('AC','AP','AM','PA','RO','RR','TO') THEN 'North'
        WHEN g.state = 'SP' THEN 'Sao Paulo'
        ELSE 'Rest of Brazil'
    END AS region,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(ord.order_delivered_customer_date, ord.order_purchase_timestamp)), 1) AS avg_actual_days
FROM orders ord
JOIN customers c ON ord.customer_id = c.customer_id
JOIN geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
WHERE ord.order_delivered_customer_date IS NOT NULL
GROUP BY region
ORDER BY avg_actual_days DESC;

#Delivery days by state
	#Roraima (RR) is the slowest at 29.3 days
	#Amapa (AP) takes 27.2 days but 97% is still "on time": the promises are long
SELECT
    g.state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(ord.order_delivered_customer_date, ord.order_purchase_timestamp)), 1) AS avg_actual_days,
    ROUND(SUM(CASE WHEN DATE(ord.order_delivered_customer_date) <= DATE(ord.order_estimated_delivery_date) THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_on_time
FROM orders ord
JOIN customers c ON ord.customer_id = c.customer_id
JOIN geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
WHERE ord.order_delivered_customer_date IS NOT NULL
AND g.state IS NOT NULL
GROUP BY g.state
ORDER BY avg_actual_days DESC;
