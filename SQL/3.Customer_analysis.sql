WITH customer_sum AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        COUNT(o.order_id) AS order_count,
        SUM(o.order_total) AS total_revenue,
        AVG(o.order_total) AS avg_order_value
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_id,
        c.customer_name,
        c.customer_segment
)
SELECT
    customer_segment,
    COUNT(customer_id) AS total_customers,
    SUM(order_count) AS total_orders,
    SUM(total_revenue) AS total_revenue,
    SUM(total_revenue) / SUM(order_count) AS avg_order_value
FROM customer_sum
GROUP BY customer_segment
ORDER BY total_revenue DESC;

WITH customer_date AS (SELECT 
    c.customer_id,
    order_date,
    o.order_total,
    min(order_date) OVER (partition by c.customer_id) AS cohort_date
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id)
, coh_month AS (SELECT 
    customer_id,
    DATE_TRUNC('month', cohort_date) AS cohort_month,
    DATE_TRUNC('month', order_date) AS order_month,
    SUM(order_total) AS total_revenue
    FROM customer_date
GROUP BY customer_id, cohort_month, order_month
ORDER BY customer_id, cohort_month, order_month)
, cohorta as (SELECT *,
    (
        EXTRACT(YEAR FROM order_month) -
        EXTRACT(YEAR FROM cohort_month)
    ) * 12
    +
    (
        EXTRACT(MONTH FROM order_month) -
        EXTRACT(MONTH FROM cohort_month)
    ) AS cohort_age
FROM coh_month
ORDER BY customer_id, order_month)
,cohct AS (SELECT 
    DISTINCT
    cohort_month,
    cohort_age,
    COUNT(customer_id) AS tot_cust,
    SUM(total_revenue) AS tot_revenue
FROM cohorta
GROUP BY cohort_month, cohort_age
ORDER BY cohort_month, cohort_age)
, coh_size AS (
    SELECT *,
    MAX(tot_cust) OVER (PARTITION BY cohort_month) AS cohort_size
FROM cohct
)
,Coh_details AS(SELECT *,
   ROUND((tot_cust*100.0/cohort_size), 2) AS retention_rate,
    ROUND((tot_revenue/tot_cust), 2) AS revenue_per_cust
FROM coh_size)
,last_month AS(
    SELECT 
    date_trunc('month',MAX(order_date)) AS last_order_month
    FROM orders
)
,cohort_eligibility AS (SELECT 
c.*,
(EXTRACT (YEAR FROM l.last_order_month )-EXTRACT (YEAR FROM c.cohort_month))*12
+
(EXTRACT(MONTH FROM l.last_order_month)-EXTRACT(MONTH FROM c.cohort_month))
AS max_age
FROM Coh_details c 
CROSS JOIN last_month l)
,age as (
    SELECT DISTINCT 
    cohort_age
    FROM Coh_details
)
,elg_coh as (
SELECT DISTINCT 
cohort_month,
cohort_size,
max_age 
FROM cohort_eligibility)
,elg_cus AS (SELECT 
a.cohort_age ,
SUM(e.cohort_size) AS eligable_customers
FROM age a
JOIN elg_coh e
ON e.max_age >=a.cohort_age
GROUP BY a.cohort_age
ORDER BY a.cohort_age )
SELECT 
c.cohort_age,
SUM(tot_cust) AS active_customer, 
e.eligable_customers,
ROUND(
        SUM(c.tot_cust) * 100.0 / e.eligable_customers,
        2
    ) AS overall_retention_rate,
    SUM(c.tot_revenue) AS total_revenue,
    ROUND(
        SUM(c.tot_revenue) / SUM(c.tot_cust),
        2
    ) AS revenue_per_active_customer
FROM Coh_details c
JOIN elg_cus e on e.cohort_age=c.cohort_age
WHERE c.cohort_age>0
GROUP BY c.cohort_age,e.eligable_customers
ORDER BY c.cohort_age
