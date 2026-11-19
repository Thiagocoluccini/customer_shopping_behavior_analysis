-- Full refresh of the dimensional model from public.customer.
-- Run 01_create_schema.sql first, then execute this script.
-- The TRUNCATE is intentional: this script rebuilds the model from the source table.

BEGIN;

TRUNCATE TABLE
    analytics_customer.fact_customer_purchase,
    analytics_customer.dim_customer,
    analytics_customer.dim_payment_method,
    analytics_customer.dim_location,
    analytics_customer.dim_shipping,
    analytics_customer.dim_frequency_buy,
    analytics_customer.dim_product
RESTART IDENTITY;

INSERT INTO analytics_customer.dim_customer (
    customer_id, age, age_group, gender
)
SELECT DISTINCT
    customer_id, age, age_group, gender
FROM public.customer;

INSERT INTO analytics_customer.dim_payment_method (payment_method)
SELECT DISTINCT payment_method
FROM public.customer
WHERE payment_method IS NOT NULL
ON CONFLICT (payment_method) DO NOTHING;

INSERT INTO analytics_customer.dim_location (state_name)
SELECT DISTINCT location
FROM public.customer
WHERE location IS NOT NULL
ON CONFLICT (state_name) DO NOTHING;

INSERT INTO analytics_customer.dim_shipping (shipping_type)
SELECT DISTINCT shipping_type
FROM public.customer
WHERE shipping_type IS NOT NULL
ON CONFLICT (shipping_type) DO NOTHING;

INSERT INTO analytics_customer.dim_frequency_buy (frequency_name, frequency_days)
SELECT DISTINCT frequency_of_purchases, purchase_frequency_days
FROM public.customer
WHERE frequency_of_purchases IS NOT NULL
  AND purchase_frequency_days IS NOT NULL
ON CONFLICT (frequency_name) DO NOTHING;

INSERT INTO analytics_customer.dim_product (
    product_name, category, color, size, season
)
SELECT DISTINCT
    item_purchased, category, color, size, season
FROM public.customer
WHERE item_purchased IS NOT NULL
  AND category IS NOT NULL
  AND color IS NOT NULL
  AND size IS NOT NULL
  AND season IS NOT NULL
ON CONFLICT (product_name, category, color, size, season) DO NOTHING;

INSERT INTO analytics_customer.fact_customer_purchase (
    customer_id,
    payment_method_id,
    id_location,
    id_shipping,
    id_frequency_buy,
    id_product,
    purchase_amount,
    review_rating,
    subscription_status,
    discount_applied,
    previous_purchases
)
SELECT
    c.customer_id,
    dpm.payment_method_id,
    dl.id_location,
    ds.id_shipping,
    dfb.id_frequency_buy,
    dp.id_product,
    c.purchase_amount::NUMERIC(10,2),
    c.review_rating::NUMERIC(3,2),
    LOWER(c.subscription_status) = 'yes',
    LOWER(c.discount_applied) = 'yes',
    c.previous_purchases
FROM public.customer AS c
JOIN analytics_customer.dim_customer AS dc
    ON c.customer_id = dc.customer_id
JOIN analytics_customer.dim_payment_method AS dpm
    ON c.payment_method = dpm.payment_method
JOIN analytics_customer.dim_location AS dl
    ON c.location = dl.state_name
JOIN analytics_customer.dim_shipping AS ds
    ON c.shipping_type = ds.shipping_type
JOIN analytics_customer.dim_frequency_buy AS dfb
    ON c.frequency_of_purchases = dfb.frequency_name
JOIN analytics_customer.dim_product AS dp
    ON c.item_purchased = dp.product_name
   AND c.category = dp.category
   AND c.color = dp.color
   AND c.size = dp.size
   AND c.season = dp.season
ON CONFLICT (customer_id) DO NOTHING;

COMMIT;

-- Post-load checks
SELECT COUNT(*) AS source_rows FROM public.customer;
SELECT COUNT(*) AS fact_rows FROM analytics_customer.fact_customer_purchase;
