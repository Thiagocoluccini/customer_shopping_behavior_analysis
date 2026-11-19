# Data Dictionary

Field descriptions are based on the supplied dataset column names and the project transformations.

| Field | Description |
|---|---|
| `customer_id` | Unique customer identifier |
| `age` | Customer age |
| `gender` | Customer gender |
| `item_purchased` | Purchased item |
| `category` | Product category |
| `purchase_amount` | Purchase amount in USD |
| `location` | U.S. state |
| `size` | Product size |
| `color` | Product color |
| `season` | Season associated with the record |
| `review_rating` | Product review rating |
| `subscription_status` | Whether the customer is subscribed |
| `shipping_type` | Shipping method |
| `discount_applied` | Whether a discount was applied |
| `promo_code_used` | Whether a promo code was used; identical to discount_applied in this dataset and removed during preparation |
| `previous_purchases` | Number of previous purchases reported in the dataset |
| `payment_method` | Payment method |
| `frequency_of_purchases` | Reported purchase frequency |
| `age_group` | Age quartile group derived during preparation |
| `purchase_frequency_days` | Approximate days mapped from the reported frequency label |


**Dataset grain:** one row per unique customer ID in the supplied file. The source does not provide a purchase date or transaction ID.
