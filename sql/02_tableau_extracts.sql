USE magist;

# =============================================================================
# Tableau extracts for "Should Eniac sell premium tech on Magist?"
# Each query below makes one CSV in the data folder.
# The line "-- @export name.csv" above each query gives the file name.
# In MySQL Workbench: run one query, then click Export in the result grid
# and save it as CSV with that name.
# Same definitions as 01_market_entry.sql.
# =============================================================================


-- @export monthly_orders.csv
#All orders per month, Jan 2017 to Aug 2018
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01') AS month, COUNT(*) AS orders
FROM orders
WHERE order_purchase_timestamp >= '2017-01-01'
AND order_purchase_timestamp < '2018-09-01'
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01')
ORDER BY month;


-- @export monthly_tech.csv
#Tech and premium tech items sold per month, Jan 2017 to Aug 2018
SELECT
    DATE_FORMAT(ord.order_purchase_timestamp, '%Y-%m-01') AS month,
    COUNT(*) AS tech_items,
    SUM(CASE WHEN o.price > 500 THEN 1 ELSE 0 END) AS premium_tech_items,
    ROUND(SUM(o.price), 2) AS tech_revenue,
    ROUND(SUM(CASE WHEN o.price > 500 THEN o.price ELSE 0 END), 2) AS premium_tech_revenue
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
JOIN orders ord ON o.order_id = ord.order_id
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
AND ord.order_purchase_timestamp >= '2017-01-01'
AND ord.order_purchase_timestamp < '2018-09-01'
GROUP BY DATE_FORMAT(ord.order_purchase_timestamp, '%Y-%m-01')
ORDER BY month;


-- @export tech_categories.csv
SELECT
    pc.product_category_name_english AS category,
    COUNT(*) AS items_sold,
    ROUND(COUNT(*) * 100 / 17271, 2) AS pct_of_tech_items,
    ROUND(AVG(o.price), 2) AS avg_price,
    ROUND(SUM(o.price), 2) AS revenue,
    SUM(CASE WHEN o.price > 500 THEN 1 ELSE 0 END) AS premium_items
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
GROUP BY pc.product_category_name_english
ORDER BY items_sold DESC;


-- @export tech_price_bands.csv
SELECT
    CASE
        WHEN o.price <= 50 THEN '1. up to 50'
        WHEN o.price <= 100 THEN '2. 50-100'
        WHEN o.price <= 200 THEN '3. 100-200'
        WHEN o.price <= 500 THEN '4. 200-500'
        WHEN o.price <= 1000 THEN '5. 500-1000'
        ELSE '6. over 1000'
    END AS price_band,
    CASE WHEN o.price > 500 THEN 'premium' ELSE 'not premium' END AS premium,
    COUNT(*) AS items_sold,
    ROUND(COUNT(*) * 100 / 17271, 2) AS pct_of_tech_items,
    ROUND(SUM(o.price), 2) AS revenue
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
GROUP BY price_band, premium
ORDER BY price_band;


-- @export premium_sellers.csv
#All 91 sellers of premium tech. seller = first 8 characters of the seller id.
SELECT
    LEFT(o.seller_id, 8) AS seller,
    COUNT(*) AS premium_items,
    ROUND(COUNT(*) * 100 / 567, 1) AS pct_of_premium_items,
    ROUND(SUM(o.price), 2) AS premium_revenue
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE pc.product_category_name_english IN ('computers','computers_accessories','electronics','telephony','fixed_telephony','audio','consoles_games','pc_gamer','tablets_printing_image','cine_photo')
AND o.price > 500
GROUP BY o.seller_id
ORDER BY premium_items DESC, premium_revenue DESC;


-- @export delivery_by_segment.csv
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


-- @export delivery_days_distribution.csv
#Delivered orders by number of days to deliver (everything above 60 counted as 60)
#Use for a histogram with a reference line at 14 days
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
    CASE WHEN DATEDIFF(ord.order_delivered_customer_date, ord.order_purchase_timestamp) > 60 THEN 60
         ELSE DATEDIFF(ord.order_delivered_customer_date, ord.order_purchase_timestamp) END AS delivery_days,
    COUNT(*) AS delivered_orders
FROM orders ord
WHERE ord.order_delivered_customer_date IS NOT NULL
GROUP BY segment, delivery_days
ORDER BY segment DESC, delivery_days;


-- @export reviews_by_delivery.csv
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


-- @export delivery_by_state.csv
#state_name is there so Tableau can draw the map (geographic role State/Province, country Brazil)
SELECT
    g.state,
    CASE
        WHEN g.state = 'AC' THEN 'Acre'
        WHEN g.state = 'AL' THEN 'Alagoas'
        WHEN g.state = 'AP' THEN 'Amapá'
        WHEN g.state = 'AM' THEN 'Amazonas'
        WHEN g.state = 'BA' THEN 'Bahia'
        WHEN g.state = 'CE' THEN 'Ceará'
        WHEN g.state = 'DF' THEN 'Distrito Federal'
        WHEN g.state = 'ES' THEN 'Espírito Santo'
        WHEN g.state = 'GO' THEN 'Goiás'
        WHEN g.state = 'MA' THEN 'Maranhão'
        WHEN g.state = 'MT' THEN 'Mato Grosso'
        WHEN g.state = 'MS' THEN 'Mato Grosso do Sul'
        WHEN g.state = 'MG' THEN 'Minas Gerais'
        WHEN g.state = 'PA' THEN 'Pará'
        WHEN g.state = 'PB' THEN 'Paraíba'
        WHEN g.state = 'PR' THEN 'Paraná'
        WHEN g.state = 'PE' THEN 'Pernambuco'
        WHEN g.state = 'PI' THEN 'Piauí'
        WHEN g.state = 'RJ' THEN 'Rio de Janeiro'
        WHEN g.state = 'RN' THEN 'Rio Grande do Norte'
        WHEN g.state = 'RS' THEN 'Rio Grande do Sul'
        WHEN g.state = 'RO' THEN 'Rondônia'
        WHEN g.state = 'RR' THEN 'Roraima'
        WHEN g.state = 'SC' THEN 'Santa Catarina'
        WHEN g.state = 'SP' THEN 'São Paulo'
        WHEN g.state = 'SE' THEN 'Sergipe'
        WHEN g.state = 'TO' THEN 'Tocantins'
    END AS state_name,
    CASE
        WHEN g.state IN ('AC','AP','AM','PA','RO','RR','TO') THEN 'North'
        WHEN g.state = 'SP' THEN 'Sao Paulo'
        ELSE 'Rest of Brazil'
    END AS region,
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
