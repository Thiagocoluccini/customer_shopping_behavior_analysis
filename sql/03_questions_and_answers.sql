-- Analytical SQL questions using the analytics_customer star schema.
-- Execute 01_create_schema.sql and 02_load_dimensions_and_fact.sql first.

-- QUESTION 1: What is the total purchase amount recorded for male vs. female customer records?
SELECT
    dc.gender,
    COUNT(*) AS customer_records,
    SUM(f.purchase_amount) AS total_purchase_amount,
    ROUND(AVG(f.purchase_amount), 2) AS avg_purchase_amount
FROM analytics_customer.fact_customer_purchase AS f
JOIN analytics_customer.dim_customer AS dc
    ON f.customer_id = dc.customer_id
GROUP BY dc.gender
ORDER BY total_purchase_amount DESC;

-- QUESTION 2: Which customers used a discount and have a purchase amount above the overall average?
SELECT
    f.customer_id,
    f.purchase_amount
FROM analytics_customer.fact_customer_purchase AS f
WHERE f.discount_applied IS TRUE
  AND f.purchase_amount > (
      SELECT AVG(purchase_amount)
      FROM analytics_customer.fact_customer_purchase
  )
ORDER BY f.purchase_amount DESC;

-- QUESTION 3: What are the five products with the highest average review rating?
SELECT
    dp.product_name,
    ROUND(AVG(f.review_rating), 2) AS avg_review_rating,
    COUNT(*) AS customer_records
FROM analytics_customer.fact_customer_purchase AS f
JOIN analytics_customer.dim_product AS dp
    ON f.id_product = dp.id_product
GROUP BY dp.product_name
ORDER BY avg_review_rating DESC, customer_records DESC, dp.product_name
LIMIT 5;

-- QUESTION 4: Compare average purchase amounts for Standard and Express shipping.
SELECT
    ds.shipping_type,
    ROUND(AVG(f.purchase_amount), 2) AS avg_purchase_amount,
    COUNT(*) AS customer_records
FROM analytics_customer.fact_customer_purchase AS f
JOIN analytics_customer.dim_shipping AS ds
    ON f.id_shipping = ds.id_shipping
WHERE LOWER(ds.shipping_type) IN ('express', 'standard')
GROUP BY ds.shipping_type
ORDER BY ds.shipping_type;

-- QUESTION 5: Compare average and total purchase amounts by subscription status.
SELECT
    CASE WHEN f.subscription_status THEN 'Subscribed' ELSE 'Not subscribed' END AS subscription_group,
    COUNT(DISTINCT f.customer_id) AS customer_records,
    ROUND(AVG(f.purchase_amount), 2) AS avg_purchase_amount,
    SUM(f.purchase_amount) AS total_purchase_amount
FROM analytics_customer.fact_customer_purchase AS f
GROUP BY f.subscription_status
ORDER BY f.subscription_status DESC;

-- QUESTION 6: Which five products have the highest percentage of records with a discount applied?
SELECT
    dp.product_name,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE f.discount_applied IS TRUE)
        / NULLIF(COUNT(*), 0),
        2
    ) AS discount_usage_rate_pct,
    COUNT(*) AS customer_records
FROM analytics_customer.fact_customer_purchase AS f
JOIN analytics_customer.dim_product AS dp
    ON f.id_product = dp.id_product
GROUP BY dp.product_name
ORDER BY discount_usage_rate_pct DESC, customer_records DESC, dp.product_name
LIMIT 5;

-- QUESTION 7: How are customer records distributed by the number of previous purchases?
-- The dataset minimum is one previous purchase, so the labels avoid calling this group 'New'.
WITH customer_segments AS (
    SELECT
        customer_id,
        CASE
            WHEN previous_purchases = 1 THEN '1 prior purchase'
            WHEN previous_purchases BETWEEN 2 AND 10 THEN '2-10 prior purchases'
            ELSE '11+ prior purchases'
        END AS purchase_history_segment
    FROM analytics_customer.fact_customer_purchase
)
SELECT
    purchase_history_segment,
    COUNT(*) AS customer_records,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct
FROM customer_segments
GROUP BY purchase_history_segment
ORDER BY customer_records DESC;

-- QUESTION 8: What are the top three most frequently recorded products within each category?
WITH product_counts AS (
    SELECT
        dp.category,
        dp.product_name,
        COUNT(*) AS customer_records,
        ROW_NUMBER() OVER (
            PARTITION BY dp.category
            ORDER BY COUNT(*) DESC, dp.product_name ASC
        ) AS item_rank
    FROM analytics_customer.fact_customer_purchase AS f
    JOIN analytics_customer.dim_product AS dp
        ON f.id_product = dp.id_product
    GROUP BY dp.category, dp.product_name
)
SELECT
    category,
    product_name,
    customer_records,
    item_rank
FROM product_counts
WHERE item_rank <= 3
ORDER BY category, item_rank;

-- QUESTION 9: Compare subscription rates for records with more than five previous purchases vs. all others.
WITH purchase_history_groups AS (
    SELECT
        customer_id,
        subscription_status,
        CASE
            WHEN previous_purchases > 5 THEN 'More than 5 previous purchases'
            ELSE '5 or fewer previous purchases'
        END AS purchase_history_group
    FROM analytics_customer.fact_customer_purchase
)
SELECT
    purchase_history_group,
    COUNT(*) AS customer_records,
    COUNT(*) FILTER (WHERE subscription_status IS TRUE) AS subscribed_records,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE subscription_status IS TRUE)
        / NULLIF(COUNT(*), 0),
        2
    ) AS subscription_rate_pct
FROM purchase_history_groups
GROUP BY purchase_history_group
ORDER BY purchase_history_group;

-- QUESTION 10: What is the purchase-amount contribution of each age group?
SELECT
    dc.age_group,
    COUNT(*) AS customer_records,
    SUM(f.purchase_amount) AS total_purchase_amount,
    ROUND(
        100.0 * SUM(f.purchase_amount)
        / NULLIF(SUM(SUM(f.purchase_amount)) OVER (), 0),
        2
    ) AS purchase_amount_share_pct
FROM analytics_customer.fact_customer_purchase AS f
JOIN analytics_customer.dim_customer AS dc
    ON f.customer_id = dc.customer_id
GROUP BY dc.age_group
ORDER BY total_purchase_amount DESC;
