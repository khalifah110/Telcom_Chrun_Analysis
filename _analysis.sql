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


--1.What is the average monthly charge for churned vs non-churned customers?
SELECT
    s.churn_value,
    AVG(c.monthly_charges) AS avg_monthly_charge
FROM churn c
JOIN status s
    ON c.status_id = s.status_id
GROUP BY s.churn_value;


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


-- 4.Which customers have monthly charges higher than the overall average?
SELECT
    customer_id,
    monthly_charges
FROM churn
WHERE monthly_charges >
      (SELECT AVG(monthly_charges) FROM churn);


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
