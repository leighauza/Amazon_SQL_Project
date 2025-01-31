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