# Customer Shopping Behavior Analysis

An end-to-end analytics project combining Python, Pandas, PostgreSQL, dimensional modeling, SQL analysis, and Power BI.

## Project Overview

This project explores a customer shopping behavior dataset and demonstrates a practical analytics workflow: data inspection and preparation with Pandas, loading data into PostgreSQL, designing a star schema, answering business questions with SQL, and presenting findings in Power BI.

## Dataset

- **Records:** 3,900
- **Original attributes:** 18
- **Unique customer IDs:** 3,900
- **Locations:** 50 U.S. states
- **Missing values:** 37 missing review ratings; imputed using the median rating within each product category.

The supplied dataset contains one row per unique customer ID. It does **not** include a purchase timestamp or transaction identifier. Therefore, the analysis is cross-sectional: it compares the supplied customer records and their reported purchase-history attributes. It does not reconstruct transaction timelines, cohort retention, or customer lifetime value.

The raw CSV is included in `data/customer_shopping_behavior.csv`. The supplied file was checked for duplicate rows and unique customer identifiers before analysis.

## Repository Structure

```text
customer-shopping-behavior-analysis/
├── data/
│   └── customer_shopping_behavior.csv
├── notebooks/
│   └── customer_shopping_notebook.ipynb
├── sql/
│   ├── 01_create_schema.sql
│   ├── 02_load_dimensions_and_fact.sql
│   └── 03_questions_and_answers.sql
├── docs/
│   ├── star_schema.pdf
│   ├── star_schema.png
│   └── data_dictionary.md
├── presentation/
│   └── Customer-Shopping-Behavior-Analysis.pptx
├── dashboard/
│   └── customer_shopping_dashboard.pbix
├── .env.example
├── .gitignore
├── requirements.txt
└── README.md
```

## Workflow

### 1. Data Preparation with Python and Pandas

The notebook performs:
- Dataset inspection and missing-value analysis.
- Median imputation of missing review ratings by product category.
- Column-name standardization to lowercase `snake_case`.
- Creation of age groups using quartile-based bins.
- Mapping purchase-frequency labels to an approximate number of days.
- Removal of `promo_code_used` after verifying that it duplicates `discount_applied` in this dataset.
- Loading the prepared dataset into PostgreSQL when a database connection is configured.

### 2. PostgreSQL Integration

The notebook loads the prepared DataFrame into `public.customer`. Database credentials are read from a local `.env` file through the `DATABASE_URL` environment variable. The `.env` file must never be committed.

### 3. Dimensional Modeling

The SQL scripts create the `analytics_customer` schema with six dimensions:
- `dim_customer`
- `dim_location`
- `dim_shipping`
- `dim_frequency_buy`
- `dim_payment_method`
- `dim_product`

The central table is `fact_customer_purchase`.

![Customer Shopping Behavior star schema](docs/star_schema.png)

**Fact-table grain:** one row per unique customer ID in the supplied dataset. This reflects the source data, which has 3,900 unique customer IDs and no transaction timestamp or transaction ID. The fact table includes purchase amount, review rating, subscription status, discount usage, and previous-purchase count, with foreign keys to the dimensions.

### 4. SQL Analysis

`sql/03_questions_and_answers.sql` contains ten analytical questions covering:
- Total purchase amount and average purchase amount by gender.
- Discount use and above-average purchase amounts.
- Highest-rated products.
- Purchase amount by shipping type.
- Subscription comparisons.
- Discount-use rates by product.
- Segments based on previous-purchase counts.
- Top products within each category.
- Subscription rates by previous-purchase group.
- Purchase-amount contribution by age group.

### 5. Power BI

The Power BI report is included in `dashboard/`. If the PostgreSQL connection differs from the original development environment, update the data-source settings in Power BI Desktop before refreshing the report.

## Setup and Execution

### Prerequisites

- Python 3.10 or later
- PostgreSQL
- JupyterLab or Visual Studio Code with the Jupyter extension
- Power BI Desktop (optional, to refresh or inspect the dashboard)

### Install dependencies

```bash
python -m venv .venv
```

Activate the environment and install packages:

```bash
python -m pip install -r requirements.txt
```

### Configure PostgreSQL

1. Create a PostgreSQL database for the project.
2. Copy `.env.example` to `.env`.
3. Set `DATABASE_URL` in `.env`, for example:

```text
DATABASE_URL=postgresql+psycopg2://USERNAME:PASSWORD@HOST:5432/DATABASE_NAME
```

4. Open and execute `notebooks/customer_shopping_notebook.ipynb`. The notebook prepares the data and loads `public.customer` if `DATABASE_URL` is configured. If it is not configured, the database export is skipped.
5. Execute the SQL scripts in order:
   - `sql/01_create_schema.sql`
   - `sql/02_load_dimensions_and_fact.sql`
   - `sql/03_questions_and_answers.sql`

The load script performs a full refresh of the dimensional tables from `public.customer` each time it runs.

## Selected Findings

- Male records account for 68% of the sample and approximately 67.7% of total purchase amount. Average purchase amounts are similar: about **$59.54** for male records and **$60.25** for female records. The difference in total purchase amount is mainly associated with the group-size difference, not a higher average purchase amount.
- Clothing represents approximately **44.7%** of total purchase amount and is also the largest category by record count.
- Average purchase amount is similar for subscribed and non-subscribed records (**$59.49** vs. **$59.87**).
- Gloves have the highest average review rating after category-median imputation (**3.86**).
- Hats have the highest discount-use rate in the sample (**50%** of hat records have a discount applied).
- Approximately **79.9%** of records report 11 or more previous purchases.

These are descriptive findings from the supplied sample and should not be interpreted as causal effects.

## Limitations

- There is no purchase date or transaction ID, so time-series purchase trends and longitudinal customer retention cannot be measured.
- `previous_purchases` is a historical count supplied in the dataset; it is not a sequence of observed transactions in this project.
- The subscription comparison is observational and does not establish that subscription status causes higher or lower spending.
- Profit margins, acquisition costs, and conversion funnel data are not available, so discount profitability and conversion impact cannot be quantified.

## Technologies

Python, Pandas, SQLAlchemy, PostgreSQL, SQL, dimensional modeling (star schema), Power BI, Jupyter Notebook.
