# Telcom_Chrun_Analysis

**Business Problem Statement:** Telecom Retention & Revenue Growth

*From: Chief Operating Officer (COO) / VP of Customer Success*.

​*To: Lead Data Analyst*.

*Subject: Urgent:* Strategic Review of Customer Churn & Market Expansion*
​Our latest quarterly review shows a significant fluctuation in our market share across California. While our total revenue sits at $21.36M, we are concerned that our "leaky bucket" (customer churn) is offsetting our acquisition efforts. We need a comprehensive intelligence dashboard to move from reactive troubleshooting to proactive retention.
​Please analyze our consumer behavior and service data to provide clear answers to the following strategic pillars:

* ​What is our current churn rate, and what is the total Revenue.
* ​Why exactly are they leaving? 
* ​Which service offerings (Internet Type/Contract) are most vulnerable to competitor poaching?
* ​What is the percentage of customers that subcribe to Premium Tech Support.
* ​Which cities are our "Profit Strongholds" (High Revenue/High Loyalty) and which are "Danger Zones" (High Churn Rate)
* ​Which age groups have the most churn rate (Targeted for Marketing). 
* ​How long is the average customer "lifespan" (tenure) before they decide to leave?
* ​what is the Average customer  Satisfaction Score. 
* What are the most acceptable payments method. 
* What is the rate of our senior citizen of all customer.


# Project Diagram
<img width="1178" height="610" alt="tel" src="https://github.com/user-attachments/assets/9f5ed4cd-098c-41d1-a2b3-23d476a3231d" />

# Project Overview

**Dataset Describtion**
- `Fact_churn`
- `dim_location`
- `dim_services`
- `dim_population`
- `dim_demographic`
- `dim_status`

## 🧹 Data Cleaning & Preparation

To prepare the dataset for analysis and data modeling, the following data cleaning steps were performed:

- We separated three (3) flat source tables into *Fact* and *Dimension* tables following dimensional modeling principles.
- Power Query (Excel) was used to *remove duplicate records* from all dimension ``dim_`` tables to ensure uniqueness.
- The *Trim* transformation in Power Query was applied to relevant text columns to remove leading and trailing spaces and ensure consistency.
- Missing values in the ``Fact_Churn`` table were handled by *replacing null values with the minimum value of each respective column*, where appropriate.
- A *surrogate key* was generated for the Dim_Location table to enable a reliable and efficient relationship with the ``Fact_Churn`` table.


**Databased Design**

* Designed and implemented a dimensional data model in PostgreSQL, including fact and dimension tables to support analytical workloads.

```sql
-- 1. Location Table (Dimension)
CREATE TABLE location (
    location_id SERIAL PRIMARY KEY, -- Surrogate Key
    country VARCHAR(50),
    states VARCHAR(50),
    city VARCHAR(100),
    zip_code VARCHAR(20) UNIQUE,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

-- 2. Population Table (Now links via Zip Code)
CREATE TABLE population (
    zip_code VARCHAR(20) PRIMARY KEY REFERENCES location(zip_code),
    population_count INT
);


-- 3. Demographic Table (Dimension)
CREATE TABLE demographic (
    demographic_id PRIMARY KEY, -- Surrogate Key
    gender VARCHAR(20),
    age INT,
    under_30 BOOLEAN,
    senior_citizen BOOLEAN,
    married BOOLEAN,
    has_dependents BOOLEAN,
    number_of_dependents INT
);

-- 4. Status Table (Dimension)
CREATE TABLE status (
    status_id PRIMARY KEY,
    quarter VARCHAR(5),
    customer_status VARCHAR(20),
    churn_label VARCHAR(10),
    churn_value BOOLEAN,
    churn_category VARCHAR(50),
    churn_reason TEXT
);

-- 5. Service Table (Dimension)
CREATE TABLE service (
    service_id  PRIMARY KEY,
    phone_service BOOLEAN,
    multiple_lines BOOLEAN,
    internet_service BOOLEAN,
    internet_type VARCHAR(50),
    contract_type VARCHAR(50),
    payment_method VARCHAR(50)
);

-- 6. Churn Table (The Fact Table - Connecting everything)
Create Table
churn(
customer_id VARCHAR(20),
location_id VARCHAR(20) FOREIGN KEY,
service_id VARCHAR(20) FOREIGN KEY,
demographics_id VARCHAR(20) FOREIGN KEY,
status_id VARCHAR(20) FOREIGN KEY,
tenure_months INT,
churn_score INT,
cltv INT,
monthly_charges NUMERIC(10,2),
total _charges NUMERIC(10,2),
total_refunds NUMERIC(10,2),
total_long_distance_charges NUMERIC(10,2),
total_revenue NUMERIC(10,2),
satisfaction_score INT
);
```
* After loading the data into PostgreSQL tables, exploratory and validation analyses were performed using SQL in VS Code.


```sql
--1.What is the average monthly charge for churned vs non-churned customers?
SELECT
    s.churn_value,
    AVG(c.monthly_charges) AS avg_monthly_charge
FROM churn c
JOIN status s
    ON c.status_id = s.status_id
GROUP BY s.churn_value;
```

### Average Monthly Charges by Churn Status

| Churn Status | Average Monthly Charge ($) |
|-------------|----------------------------|
| No (Retained Customers) | 62.69 |
| Yes (Churned Customers) | 70.47 |



```sql
-- 2.How many customers churned by contract type?
SELECT
    sv.contract,
    COUNT(*) AS churned_customers
FROM churn c
JOIN status s
    ON c.status_id = s.status_id
JOIN service sv
    ON c.service_id = sv.service_id
WHERE s.churn_value = TRUE
GROUP BY sv.contract
ORDER BY churned_customers DESC;
```
### Churned Customers by Contract Type

| Contract Type | Churned Customers |
|--------------|-------------------|
| Month-to-Month | 1655 |
| One Year | 166 |
| Two Year | 48 |



```sql
--3 Which cities have the highest number of churned customers?

SELECT
    l.city,
    COUNT(*) AS churn_count
FROM churn c
JOIN status s
    ON c.status_id = s.status_id
JOIN location_ l
    ON c.location_id = l.location_id
WHERE s.churn_value = TRUE
GROUP BY l.city
ORDER BY churn_count DESC;
```
### Top 10 Cities by Churn Count

| City | Churn Count |
|------|-------------|
| San Diego | 191 |
| Los Angeles | 108 |
| San Francisco | 39 |
| Sacramento | 38 |
| San Jose | 34 |
| Fallbrook | 30 |
| Temecula | 25 |
| Fresno | 22 |
| Escondido | 20 |
| Glendale | 19 |



```sql
-- 4.Which customers have monthly charges higher than the overall average?
SELECT
    customer_id,
    monthly_charges
FROM churn
WHERE monthly_charges >
      (SELECT AVG(monthly_charges) FROM churn);
```
### Top Customers by Monthly Charges

| Customer ID | Monthly Charges ($) |
|-------------|---------------------|
| 9237-HQITU | 70.70 |
| 9305-CDSKC | 99.65 |
| 7892-POOKP | 89.90 |
| 4190-MFLUW | 73.65 |
| 8779-QRDMV | 95.10 |


```sql
-- 5. Which contract types have above-average churn rates?
WITH churn_summary AS (
    SELECT
        sv.contract,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN s.churn_value = TRUE THEN 1 ELSE 0 END) AS churned_customers
    FROM churn c
    JOIN status s
        ON c.status_id = s.status_id
    JOIN service sv
        ON c.service_id = sv.service_id
    GROUP BY sv.contract
),
churn_rate AS (
    SELECT
        contract,
        churned_customers,
        total_customers,
        churned_customers::DECIMAL / total_customers AS churn_rate
    FROM churn_summary
)
SELECT *
FROM churn_rate
WHERE churn_rate >
      (SELECT AVG(churn_rate) FROM churn_rate);
```
### Churn Rate for Month-to-Month Contracts

| Contract Type | Churned Customers | Total Customers | Churn Rate |
|--------------|-------------------|----------------|------------|
| Month-to-Month | 1655 | 3610 | 45.84% |


* After performing exploratory data analysis using SQL, the PostgreSQL database was connected to Microsoft Power BI to build visualizations and answer critical business questions for decision-making.


# Data Model (Snowflake)

<img width="1309" height="602" alt="Screenshot 2026-01-22 105455" src="https://github.com/user-attachments/assets/7af8b3d6-e52d-447d-ad19-8af1a4457d3c" />




## 🧮 DAX Measures & Calculations
* The following DAX measures were created to support segmentation, customer lifetime value analysis, and churn behavior insights across the dashboard:

| Measure Name | DAX Formula | Description |
|-------------|------------|-------------|
| **Age Group** | `SWITCH(TRUE(), VALUE(dim_demographic[age]) < 18, "Under 18", VALUE(dim_demographic[age]) <= 25, "18-25", VALUE(dim_demographic[age]) <= 35, "26-35", VALUE(dim_demographic[age]) <= 45, "36-45", VALUE(dim_demographic[age]) <= 55, "46-55", VALUE(dim_demographic[age]) <= 65, "56-65", VALUE(dim_demographic[age]) <= 70, "66-70", "Elderly")` | Categorizes customers into age brackets for demographic analysis. |
| **Average CLTV** | `AVERAGE(fact_churn[cltv])` | Calculates the average customer lifetime value. |
| **Average Satisfaction Score** | `AVERAGE(fact_churn[satisfaction_score])` | Computes the mean customer satisfaction rating. |
| **Average Tenure (Months)** | `AVERAGE(fact_churn[tenure_months])` | Calculates the average customer lifespan before churn. |
| **Average Number of Dependents** | `AVERAGE(dim_demographic[dependents])` | Measures the average number of dependents per customer. |
| **Total CLTV** | `SUM(fact_churn[cltv])` | Computes total lifetime value across all customers. |



### Measures Snippet
```dax

// Customer Age Segmentation
age_group =
VAR CurrentAge = VALUE(dim_demographic[age])
RETURN
SWITCH(
    TRUE(),
    CurrentAge < 18, "Under 18",
    CurrentAge <= 25, "18-25",
    CurrentAge <= 35, "26-35",
    CurrentAge <= 45, "36-45",
    CurrentAge <= 55, "46-55",
    CurrentAge <= 65, "56-65",
    CurrentAge <= 70, "66-70",
    "Elderly"
)

// Average Customer Lifetime Value
avg_cltv = AVERAGE(fact_churn[cltv])

// Average Customer Satisfaction
avg_customers_satisfaction_rate =
AVERAGE(fact_churn[satisfaction_score])

// Average Customer Tenure
avg_month_tenure =
AVERAGE(fact_churn[tenure_months])

// Average Number of Dependents
avg_number_of_dependent =
AVERAGE(dim_demographic[dependents])

// Total Customer Lifetime Value
total_cltv =
SUM(fact_churn[cltv])
```


# Dashboard

<img width="1118" height="668" alt="1" src="https://github.com/user-attachments/assets/523b4e1f-7a49-4b73-9636-9fbecbe4989f" />

<img width="1225" height="673" alt="2" src="https://github.com/user-attachments/assets/0b31e2e9-c010-4fe7-a6c2-5c2c3007f7b6" />

<img width="1200" height="660" alt="services" src="https://github.com/user-attachments/assets/19ddc988-1d6f-4a90-903b-6dee65619a5e" />

<img width="1233" height="654" alt="4" src="https://github.com/user-attachments/assets/6a246b80-4ef8-468e-868f-999128f51a98" />




# 🔍 Business Insights

* The current customer churn rate stands at 26.54%, indicating a significant retention challenge.

* The primary driver of churn is competitive pressure, with better devices offered by competitors being the leading reason customers leave.

* Customers on Month-to-Month contracts and those using Cable internet services are the most vulnerable to competitor poaching.

* 29.02% of customers subscribe to Premium Tech Support, suggesting moderate adoption but room for growth.

* Los Angeles generates the highest revenue and has a strong base of loyal customers, while San Francisco contributes the lowest revenue among major markets. Escondido shows signs of low customer loyalty.

* The highest churn rates are observed among customers aged 36–45, 46–55, and 26–35, indicating churn risk is concentrated within the core working-age population.

* The average customer tenure is 32.37 months, providing a benchmark for expected customer lifespan.

* The average customer satisfaction score is 3.24, reflecting a need for service quality improvements.

* Bank Withdrawal is the most preferred payment method among customers.

* Senior citizens represent 16.21% of the customer base, forming a meaningful but secondary customer segment.

# 🎯 Strategic Recommendations

## 1️⃣ Strengthen Competitive Positioning

Introduce device upgrade programs and limited-time device promotions to counter competitor advantages.

Bundle devices with longer-term contracts to reduce churn risk.

## 2️⃣ Reduce Churn in High-Risk Segments

Target Month-to-Month and Cable internet customers with loyalty incentives such as discounts, service upgrades, or contract migration offers.

Prioritize retention campaigns for customers aged 26–55, as this group represents the highest churn concentration.

## 3️⃣ Expand Premium Tech Support Adoption

Position Premium Tech Support as a value-added retention tool by offering free trials or discounted bundles for at-risk customers.

Measure churn rates between subscribers and non-subscribers to validate its effectiveness as a retention lever.

## 4️⃣ Focus on City-Level Retention Strategies

Protect Los Angeles as a revenue stronghold through loyalty programs and proactive customer engagement.

Investigate churn drivers in San Francisco and Escondido to design localized retention initiatives.

## 5️⃣ Improve Customer Experience & Satisfaction

Address service quality issues to raise the satisfaction score above 3.24, focusing on network reliability, customer support response time, and service transparency.

Use satisfaction trends as an early warning indicator for churn risk.

## 6️⃣ Optimize Payment Experience

Maintain and enhance Bank Withdrawal payment options while promoting incentives for customers to adopt automated payments, reducing friction and late payments.

## 7️⃣ Develop Senior-Focused Offerings

Create simplified plans or support packages tailored to senior citizens, leveraging their relatively stable presence in the customer base.





























