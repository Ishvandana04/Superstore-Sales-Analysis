-- Superstore Sales Analytics Project
-- Dialect: PostgreSQL-compatible SQL
-- Load the supplied CSVs into orders, returns and people tables before running.

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    row_id INT,
    order_id VARCHAR(20),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(30),
    customer_id VARCHAR(20),
    customer_name VARCHAR(150),
    segment VARCHAR(30),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code INT,
    region VARCHAR(30),
    product_id VARCHAR(30),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales NUMERIC(14,2),
    quantity INT,
    discount NUMERIC(6,3),
    profit NUMERIC(14,2)
);

DROP TABLE IF EXISTS returns;
CREATE TABLE returns (
    returned VARCHAR(10),
    order_id VARCHAR(20)
);

DROP TABLE IF EXISTS people;
CREATE TABLE people (
    person VARCHAR(150),
    region VARCHAR(30)
);

-- Example import commands (edit local paths):
-- COPY orders FROM '/path/to/orders.csv' CSV HEADER;
-- COPY returns FROM '/path/to/returns.csv' CSV HEADER;
-- COPY people FROM '/path/to/people.csv' CSV HEADER;

-- 1. Overall KPIs
SELECT ROUND(SUM(sales),2) AS total_sales,
       ROUND(SUM(profit),2) AS total_profit,
       ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS profit_margin_pct,
       SUM(quantity) AS total_quantity,
       COUNT(DISTINCT order_id) AS total_orders,
       COUNT(DISTINCT customer_id) AS total_customers
FROM orders;

-- 2. Regional performance
SELECT region,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit,
       ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct,
       SUM(quantity) AS quantity
FROM orders
GROUP BY region
ORDER BY sales DESC;

-- 3. Category performance
SELECT category,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit,
       ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM orders
GROUP BY category
ORDER BY sales DESC;

-- 4. Sub-category profitability
SELECT sub_category,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit,
       ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM orders
GROUP BY sub_category
ORDER BY profit DESC;

-- 5. Loss-making sub-categories
SELECT sub_category, ROUND(SUM(sales),2) AS sales, ROUND(SUM(profit),2) AS profit
FROM orders
GROUP BY sub_category
HAVING SUM(profit) < 0
ORDER BY profit;

-- 6. Discount vs profit
SELECT discount,
       COUNT(*) AS order_lines,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit,
       ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM orders
GROUP BY discount
ORDER BY discount;

-- 7. Monthly sales and profit trend
SELECT DATE_TRUNC('month', order_date)::date AS month,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit
FROM orders
GROUP BY 1
ORDER BY 1;

-- 8. Segment comparison
SELECT segment,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit,
       ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM orders
GROUP BY segment
ORDER BY sales DESC;

-- 9. Ship mode analysis
SELECT ship_mode,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit,
       COUNT(DISTINCT order_id) AS orders
FROM orders
GROUP BY ship_mode
ORDER BY sales DESC;

-- 10. Top 10 customers by sales
SELECT customer_id, customer_name,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit
FROM orders
GROUP BY customer_id, customer_name
ORDER BY sales DESC
LIMIT 10;

-- 11. Top 10 products by profit
SELECT product_id, product_name,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit
FROM orders
GROUP BY product_id, product_name
ORDER BY profit DESC
LIMIT 10;

-- 12. Bottom 10 products by profit
SELECT product_id, product_name,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit
FROM orders
GROUP BY product_id, product_name
ORDER BY profit
LIMIT 10;

-- 13. State-level performance
SELECT state,
       ROUND(SUM(sales),2) AS sales,
       ROUND(SUM(profit),2) AS profit
FROM orders
GROUP BY state
ORDER BY profit DESC;

-- 14. Return rate by region
WITH returned_orders AS (
    SELECT DISTINCT order_id
    FROM returns
    WHERE returned = 'Yes'
)
SELECT o.region,
       COUNT(DISTINCT o.order_id) AS total_orders,
       COUNT(DISTINCT CASE WHEN r.order_id IS NOT NULL THEN o.order_id END) AS returned_orders,
       ROUND(
         COUNT(DISTINCT CASE WHEN r.order_id IS NOT NULL THEN o.order_id END)::numeric
         / NULLIF(COUNT(DISTINCT o.order_id),0) * 100, 2
       ) AS return_rate_pct
FROM orders o
LEFT JOIN returned_orders r ON o.order_id = r.order_id
GROUP BY o.region
ORDER BY return_rate_pct DESC;

-- 15. Return rate by category
WITH returned_orders AS (
    SELECT DISTINCT order_id
    FROM returns
    WHERE returned = 'Yes'
)
SELECT o.category,
       COUNT(DISTINCT o.order_id) AS total_orders,
       COUNT(DISTINCT CASE WHEN r.order_id IS NOT NULL THEN o.order_id END) AS returned_orders,
       ROUND(
         COUNT(DISTINCT CASE WHEN r.order_id IS NOT NULL THEN o.order_id END)::numeric
         / NULLIF(COUNT(DISTINCT o.order_id),0) * 100, 2
       ) AS return_rate_pct
FROM orders o
LEFT JOIN returned_orders r ON o.order_id = r.order_id
GROUP BY o.category
ORDER BY return_rate_pct DESC;

-- 16. Average order value by segment
WITH order_totals AS (
    SELECT order_id, segment, SUM(sales) AS order_sales
    FROM orders
    GROUP BY order_id, segment
)
SELECT segment,
       ROUND(AVG(order_sales),2) AS avg_order_value,
       COUNT(*) AS orders
FROM order_totals
GROUP BY segment
ORDER BY avg_order_value DESC;
