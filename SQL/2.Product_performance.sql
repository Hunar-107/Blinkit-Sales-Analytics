CREATE VIEW product_sales AS
SELECT
    o.order_id,
    o.order_date,
    oi.product_id,
    p.product_name,
    p.category,
    p.brand,
    oi.quantity,
    o.order_total,
    p.price,
    p.mrp,
    p.margin_percentage
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id;

WITH tot_rank AS (SELECT 
    category,
    product_name,
    SUM(order_total)  AS product_total,
    RANK() OVER (PARTITION BY category ORDER BY SUM(order_total) DESC) AS product_rank
FROM product_sales
GROUP BY category, product_name
ORDER BY category)
, qty_rank AS (SELECT 
    category,
    product_name,
    SUM(quantity)  AS tot_units,
    RANK() OVER (PARTITION BY category ORDER BY SUM(quantity) DESC) AS product_rank
FROM product_sales
GROUP BY category, product_name
ORDER BY category)
, tot_rank_ AS (SELECT
t.category,
t.product_name,
product_total,
tot_units,
t.product_rank AS top_rev,
q.product_rank AS top_qty
FROM tot_rank t
INNER JOIN qty_rank q
ON q.product_name=t.product_name AND q.category=t.category
)
, prod_contribution AS (SELECT 
*,
ROUND(((product_total/SUM(product_total) OVER (PARTITION BY category)))*100, 2) AS product_revenue_share,
ROUND(((tot_units/SUM(tot_units) OVER (PARTITION BY category)))*100, 2) AS product_quantity_share
FROM tot_rank_)
SELECT 
CORR(top_rev, top_qty) AS revenue_quantity_corr
FROM prod_contribution;

with brands_rev AS (SELECT
    product_id,
    category,
    product_name,
    brand,
    SUM(order_total) AS product_total,
    SUM(quantity) AS total_quantity
FROM product_sales
GROUP BY product_id, category, product_name, brand
ORDER BY category, product_name)
,brands_ranked AS (SELECT 
category,
product_name,
brand,
product_total,
total_quantity,
RANK() OVER (PARTITION BY product_name ORDER BY product_total DESC) AS brand_rev_rank,
RANK() OVER (PARTITION BY product_name ORDER BY total_quantity DESC) AS brand_qty_rank
FROM brands_rev)
,brand_corr AS (SELECT 
CORR(brand_rev_rank, brand_qty_rank) 
FROM brands_ranked)
, brand_performance AS (SELECT 
category,
product_name,
brand,
brand_rev_rank-brand_qty_rank as rank_diff,
MAX(brand_rev_rank-brand_qty_rank) OVER (PARTITION BY product_name) AS highest_performing,
MIN(brand_rev_rank-brand_qty_rank) OVER (PARTITION BY product_name) AS lowest_performing
FROM brands_ranked
ORDER BY category,product_name)
, brand_performanced_grouped AS (SELECT 
category,
product_name,
brand,
rank_diff,
CASE WHEN rank_diff = highest_performing THEN 'Highest Performing'
WHEN rank_diff = lowest_performing THEN 'Lowest Performing'
ELSE 'Average Performing'
END AS performance
FROM brand_performance)
SELECT
category,
product_name,
STRING_AGG(
    CASE WHEN performance = 'Highest Performing' THEN brand END, ', '
) AS highest_performing_brands
FROM brand_performanced_grouped
WHERE rank_diff >=2
GROUP BY category, product_name
ORDER BY category, product_name
