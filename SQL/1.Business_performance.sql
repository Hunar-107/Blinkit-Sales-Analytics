##Finding the monthly revenue 

with monthly_revenue AS (SELECT 
    TO_CHAR(DATE_TRUNC('month',order_date), 'Mon YYYY') AS order_month,
    SUM(order_total) AS tot_revenue,
    COUNT(order_id) AS monthly_order_count,
    AVG(order_total) AS avg_order_value
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY DATE_TRUNC('month', order_date) )

,prev_rev AS (SELECT 
    order_month,
    tot_revenue,
    LAG(tot_revenue) OVER () AS prev_month_rev
FROM monthly_revenue)

SELECT *,
    ((tot_revenue-prev_month_rev)/prev_month_rev)*100 AS monthly_change_rev
FROM prev_rev
WHERE prev_month_rev IS NOT NULL;

WITH cat_rev AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS order_month,
        p.category, 
        SUM(order_total) AS tot_revenue
    FROM orders O
    LEFT JOIN order_items ON O.order_id = order_items.order_id
    LEFT JOIN products p ON order_items.product_id = p.product_id
    GROUP BY p.category, order_month
    ORDER BY p.category, order_month
),
rev_change AS (
    SELECT 
        TO_CHAR(order_month, 'Mon YYYY') AS order_month,
        category,
        tot_revenue,
        LAG(tot_revenue) OVER (PARTITION BY category ORDER BY order_month) AS prev_month_rev,
        tot_revenue - (LAG(tot_revenue) OVER (PARTITION BY category ORDER BY order_month)) AS rev_change,
        ((tot_revenue - (LAG(tot_revenue) OVER (PARTITION BY category ORDER BY order_month))) / (LAG(tot_revenue) OVER (PARTITION BY category ORDER BY order_month))) * 100 AS rev_change_perc
    FROM cat_rev
)
,cat_growth AS (SELECT 
    order_month,
    category,
    tot_revenue,
    prev_month_rev,
    rev_change,
    ROUND(rev_change_perc,2) AS rev_change_perc
FROM rev_change
)
,month_ranked AS (SELECT 
    order_month,
    category,
    tot_revenue,
    (MIN(order_month) OVER(PARTITION BY category)) + INTERVAL '1 month' AS first_full_month,
    (MAX(order_month) OVER(PARTITION BY category)) - INTERVAL '1 month' AS last_full_month
FROM cat_rev)
,falrev AS (SELECT
order_month,
category,
CASE
WHEN order_month = first_full_month THEN tot_revenue END AS first_full_month_revenue,
CASE 
WHEN order_month = last_full_month THEN tot_revenue END AS last_full_month_revenue
FROM month_ranked
WHERE order_month = first_full_month
   OR order_month = last_full_month)
SELECT 
DISTINCT
category,
MAX(first_full_month_revenue) OVER(PARTITION BY category) AS first_full_month_revenue,
MAX(last_full_month_revenue) OVER(PARTITION BY category) AS last_full_month_revenue,
ROUND(((MAX(last_full_month_revenue) OVER(PARTITION BY category) - MAX(first_full_month_revenue) OVER(PARTITION BY category)) / MAX(first_full_month_revenue) OVER(PARTITION BY category)) * 100, 2) AS growth_percentage
FROM falrev
ORDER BY growth_percentage DESC
