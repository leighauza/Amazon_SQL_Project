-- Business Problems Solutions

-- #1

SELECT
  order_items.product_id,
  products.product_name,
  SUM(quantity) AS total_quantity,
  ROUND(CAST(SUM(quantity*price_per_unit) AS NUMERIC), 2) AS total_sales

FROM order_items
  LEFT JOIN products
  ON products.product_id = order_items.product_id
GROUP BY order_items.product_id, products.product_name
ORDER BY total_sales DESC
LIMIT 10;

-- #2

-- Add:column

ALTER TABLE order_items
ADD COLUMN total_sale NUMERIC;

UPDATE order_items
SET total_sale = quantity*price_per_unit;

SELECT *
FROM order_items;

--

SELECT
  category.category_id,
  category.category_name,
  SUM(total_sale) AS total_sales,
  (SUM(total_sale)/(SELECT SUM(total_sale) FROM order_items))*100
FROM order_items
LEFT JOIN  products
  ON products.product_id = order_items.product_id
LEFT JOIN category
  ON category.category_id = products.category_id
GROUP BY category.category_id, category.category_name
ORDER BY total_sales DESC;

-- #3

SELECT
  customers.customer_id,
  CONCAT(customers.first_name, ' ', customers.last_name) AS customer_name,
  ROUND(SUM(order_items.total_sale)/COUNT(orders.order_id), 2) AS average_order_value,
  COUNT(orders.order_id) AS total_orders
FROM order_items
JOIN orders ON orders.order_id = order_items.order_id
JOIN customers ON customers.customer_id = orders.customer_id

GROUP BY
  customers.customer_id
HAVING
  COUNT(orders.order_id) > 5
ORDER BY
  average_order_value DESC;

-- #4

SELECT
  month,
  year,
  total_sales,
  LAG(total_sales, 1) OVER(ORDER BY year, month) AS last_month_sale

FROM (
  SELECT
    EXTRACT(MONTH FROM order_date) as month,
    EXTRACT(YEAR FROM order_date) as year,
    ROUND(SUM(order_items.total_sale::NUMERIC), 2) as total_sales
  FROM orders
    JOIN order_items
    ON orders.order_id = order_items.order_id
  WHERE order_date BETWEEN DATE '2023-08-01' AND DATE '2024-07-30'
  GROUP BY year, month
  ORDER BY year, month
) AS table_1

-- #5

SELECT *
FROM customers as c
LEFT JOIN orders as o
ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL;

-- #6

WITH ranking_table AS (

SELECT
  c.state as state,
  ca.category_name,
  SUM(oi.total_sale) as total_sale,
  RANK () OVER(PARTITION BY c.state ORDER BY SUM(oi.total_sale) ASC) as rank

FROM orders as o
JOIN customers as c
  ON o.customer_id = c.customer_id
JOIN order_items as oi
  ON o.order_id = oi.order_id
JOIN products as p
  ON p.product_id = oi.product_id
JOIN category as ca
  ON ca.category_id = p.category_id

GROUP BY 1, 2

)

SELECT *
FROM ranking_table
WHERE rank = 1;

-- #7

SELECT
  customers.customer_id,
  CONCAT(customers.first_name, ' ', customers.last_name) AS customer_name,
  SUM(total_sale) AS CLTV,
  DENSE_RANK() OVER(ORDER BY SUM(total_sale) DESC) AS cltv_rank
FROM order_items
JOIN orders ON orders.order_id = order_items.order_id
JOIN customers ON customers.customer_id = orders.customer_id

GROUP BY
  customers.customer_id
HAVING
  COUNT(orders.order_id) > 5
;

-- #8

SELECT
  i.inventory_id,
  p.product_name,
  i.stock AS current_stock,
  i.last_stock_date,
  i.warehouse_id
FROM inventory as i
  JOIN products as p
  ON p.product_id = i.product_id
WHERE stock < 10;

-- #9

SELECT
  c.*,
  o.*,
  s.shipping_providers,
  (s.shipping_date - o.order_date) AS days_took_to_ship
FROM orders as o
JOIN customers as c
  ON c.customer_id = o.customer_id
JOIN shipping as s
  ON s.order_id = o.order_id

WHERE
  (s.shipping_date - o.order_date) > 3;

-- #10

SELECT
  payment_status,
  COUNT(*) as count,
  ROUND(COUNT(*)/(SELECT COUNT(*) FROM payments)::numeric * 100, 2) as status_percentage
FROM payments
GROUP BY payment_status;

-- #11

WITH top_sellers AS ( -- CTE: top 5 sellers based on revenue
  SELECT
    s.seller_id,
    s.seller_name,
    SUM(oi.total_sale) as total_sale
  FROM orders as o
  LEFT JOIN order_items as oi
    ON o.order_id = oi.order_id
  LEFT JOIN sellers as s
    ON s.seller_id = o.seller_id
  GROUP BY s.seller_id, s.seller_name
  ORDER BY total_sale DESC
  LIMIT 5
),

seller_reports AS ( -- CTE: to see different order status
  SELECT
    o.seller_id,
    ts.seller_name,
    o.order_status,
    COUNT(*) as order_count
  FROM orders as o
  JOIN top_sellers as ts
    ON o.seller_id = ts.seller_id
  WHERE
    o.order_status NOT IN ('Inprogress', 'Returned')
  GROUP BY o.seller_id, ts.seller_name, o.order_status
)

SELECT
  seller_id,
  seller_name,
  SUM(CASE WHEN order_status = 'Completed' THEN order_count ELSE 0 END) as completed_orders,
  SUM(CASE WHEN order_status = 'Cancelled' THEN order_count ELSE 0 END) as cancelled_orders,
  SUM(order_count) as total_orders,
  SUM(CASE WHEN order_status = 'Completed' THEN order_count ELSE 0 END)::numeric/SUM(order_count)::numeric * 100 as successful_order_percentage
FROM seller_reports
GROUP BY seller_id, seller_name;


-- #12


SELECT
  product_id,
  product_name,
  profit_margin,
  DENSE_RANK() OVER(ORDER BY profit_margin DESC) as profit_rank

FROM (
  SELECT
    p.product_id as product_id,
    p.product_name as product_name,
    -- ROUND(SUM(oi.total_sale - oi.quantity * p.cogs)::numeric, 2) as profit,
    -- DENSE_RANK () OVER(ORDER BY ROUND(SUM(oi.total_sale - oi.quantity * p.cogs)::numeric, 2) DESC) as profit_rank
    (SUM((oi.total_sale - oi.quantity * p.cogs))/
      SUM(oi.total_sale))*100::numeric as profit_margin

  FROM order_items as oi
  JOIN products as p
    ON oi.product_id = p.product_id
  GROUP BY p.product_id, p.product_name
  ORDER BY profit_margin DESC
) as table_1;


-- #13

SELECT 
  p.product_id,
  p.product_name,
  -- COUNT (*) FILTER (WHERE o.order_status = 'Returned') as returned_orders,
  -- COUNT (*) as total_orders,
  ROUND((COUNT (*) FILTER (WHERE o.order_status = 'Returned')::numeric / COUNT (*)::numeric)*100, 2) as return_rate
FROM orders as o
JOIN order_items as oi
  ON o.order_id = oi.order_id
JOIN products as p
  ON p.product_id = oi.product_id

GROUP BY 1,2
ORDER BY return_rate DESC
LIMIT 10;

-- #14

SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  c.state,
  o.order_date,
  p.payment_date

FROM orders as o 
JOIN payments as p
  ON o.order_id = p.order_id
JOIN customers as c
  ON c.customer_id = o.customer_id

WHERE p.payment_status = 'Payment Successed'
  AND o.order_status = 'Inprogress';

-- #15

SELECT
  s.seller_id,
  s.seller_name,
  MAX(o.order_date) AS last_sale_date,
  COALESCE(SUM(oi.total_sale), 0) AS total_sale

FROM sellers as s
LEFT JOIN orders as o
  ON s.seller_id = o.seller_id
JOIN order_items as oi
  ON o.order_id = oi.order_id

WHERE s.seller_id NOT IN (
  SELECT seller_id
  FROM orders
  WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
)

GROUP BY s.seller_id, s.seller_name
ORDER BY last_sale_date DESC;

-- #16

WITH initial_table AS(
  SELECT
    CONCAT(c.first_name, ' ', c.last_name) as full_name,
    COUNT(order_id) as total_orders,
    COUNT(CASE 
      WHEN order_status = 'Returned' THEN 1
      ELSE NULL
    END) AS total_returned

  FROM customers as c
  LEFT JOIN orders as o
    ON c.customer_id = o.customer_id

  GROUP BY full_name
)


SELECT *,
  CASE
    WHEN total_returned > 5 THEN 'returning'
    ELSE 'new'
  END AS customer_type
FROM initial_table;

-- 17

WITH customers_ranked AS (
  SELECT
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    c.state,
    COUNT(o.order_id) as total_orders,
    ROUND(SUM(oi.total_sale), 2) as total_sales,
    RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id) DESC, SUM(oi.total_sale) DESC) as rank

  FROM customers as c
  JOIN orders as o
    ON o.customer_id = c.customer_id
  JOIN order_items as oi
    ON oi.order_id = o.order_id

  GROUP BY c.state, c.customer_id
  ORDER BY c.state, COUNT(o.order_id) DESC
)

SELECT *
FROM customers_ranked
WHERE rank <= 5;

-- 18

SELECT
  s.shipping_providers as shipping_providers,
  COUNT(o.order_id) as total_orders,
  SUM(oi.total_sale) as total_sales,
  AVG(s.shipping_date - o.order_date) as ave_delivery_time

FROM shipping as s
JOIN orders as o
  ON s.order_id = o.order_id
JOIN order_items as oi
  ON oi.order_id = o.order_id

GROUP BY s.shipping_providers
ORDER BY total_orders DESC;

-- 19

SELECT
    p.product_id,
    p.product_name,
    ca.category_name,
    SUM(CASE
        WHEN EXTRACT(YEAR FROM o.order_date) = 2022
        THEN oi.total_sale
        ELSE 0 
        END) AS total_sale_2022,
    SUM(CASE
        WHEN EXTRACT(YEAR FROM o.order_date) = 2023
        THEN oi.total_sale
        ELSE 0 
        END) AS total_sale_2023,
    ROUND((SUM(CASE WHEN EXTRACT(YEAR FROM o.order_date) = 2023 THEN oi.total_sale ELSE 0 END)
        - SUM(CASE WHEN EXTRACT(YEAR FROM o.order_date) = 2022 THEN oi.total_sale ELSE 0 END))
        / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM o.order_date) = 2022 THEN oi.total_sale ELSE 0 END), 0)
        * 100, 2) AS ratio
    

FROM products as p
JOIN  category as ca
  ON p.category_id = ca.category_id
JOIN order_items as oi
  ON p.product_id = oi.product_id
JOIN orders as o
  ON oi.order_id = o.order_id

GROUP BY p.product_id, p.product_name, ca.category_name;

-- 20

