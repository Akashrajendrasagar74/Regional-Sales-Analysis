CREATE DATABASE sales_db;
USE sales_db;

select * from Regional_sales_data;

-- 1. Top 3 customers by revenue in each region
SELECT *
FROM (
    SELECT
        us_region,
        customer_name,
        SUM(revenue) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY us_region ORDER BY SUM(revenue) DESC) AS rnk
    FROM regional_sales_data
    GROUP BY us_region, customer_name
) t
WHERE rnk <= 3;

-- 2. Month-over-Month revenue growth %
SELECT
    order_month,
    SUM(revenue) AS monthly_revenue,
    ROUND(
        (SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY order_month)) /
        LAG(SUM(revenue)) OVER (ORDER BY order_month) * 100, 2
    ) AS mom_growth_pct
FROM regional_sales_data
GROUP BY order_month;


-- 3. Revenue contribution % by region
SELECT
    us_region,
    ROUND(SUM(revenue) * 100 /
    (SELECT SUM(revenue) FROM regional_sales_data), 2) AS revenue_pct
FROM regional_sales_data
GROUP BY us_region
ORDER BY revenue_pct DESC;

-- 4. Products profitable overall but loss-making in some region
SELECT DISTINCT product_name
FROM regional_sales_data
GROUP BY product_name
HAVING SUM(profit) > 0
AND product_name IN (
    SELECT product_name
    FROM regional_sales_data
    GROUP BY product_name, us_region
    HAVING SUM(profit) < 0
);

-- 5. Running total revenue by date
SELECT
    order_date,
    SUM(revenue) AS daily_revenue,
    SUM(SUM(revenue)) OVER (ORDER BY order_date) AS running_revenue
FROM regional_sales_data
GROUP BY order_date;

-- 6. Customers who purchased in all regions
SELECT customer_name
FROM regional_sales_data
GROUP BY customer_name
HAVING COUNT(DISTINCT us_region) =
       (SELECT COUNT(DISTINCT us_region) FROM regional_sales_data);


-- 7. Most consistent region (lowest revenue variance)
SELECT
    us_region,
    VARIANCE(revenue) AS revenue_variance
FROM regional_sales_data
GROUP BY us_region
ORDER BY revenue_variance;

-- 8. Average Order Value (AOV) per customer
SELECT
    customer_name,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_number), 2) AS avg_order_value
FROM regional_sales_data
GROUP BY customer_name;

-- 9. Budget vs Actual performance by region
SELECT
    us_region,
    SUM(revenue) AS actual_revenue,
    SUM(budget) AS budgeted_revenue,
    SUM(revenue) - SUM(budget) AS variance
FROM regional_sales_data
GROUP BY us_region;

-- 10. Customers with profit margin below company average
SELECT
    customer_name,
    SUM(profit) / SUM(revenue) * 100 AS customer_margin
FROM regional_sales_data
GROUP BY customer_name
HAVING customer_margin <
(
    SELECT SUM(profit) / SUM(revenue) * 100 FROM regional_sales_data
);