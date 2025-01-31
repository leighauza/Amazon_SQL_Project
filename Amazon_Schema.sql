
----- PARENT TABLES -----

-- category_table

CREATE  TABLE category
(
category_id INT PRIMARY KEY,
category_name VARCHAR(25)
);

-- customers_table

CREATE TABLE customers
(
  customer_id INT PRIMARY KEY,
  first_name VARCHAR(20),
  last_name VARCHAR(20),
  state VARCHAR(20)
);

-- sellers_table

CREATE TABLE sellers
(
  seller_id INT PRIMARY KEY,
  seller_name VARCHAR(30),
  origin VARCHAR(15)
);

----- CHILD TABLES -----

-- products_table

CREATE TABLE products
(
  product_id INT PRIMARY KEY,
  product_name VARCHAR(80),
  price FLOAT,
  cogs FLOAT,
  category_id INT, -- FK
  CONSTRAINT products_fk_category FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- orders_table

CREATE TABLE orders
(
  order_id INT PRIMARY KEY,
  order_date DATE,
  customer_id INT, -- FK
  seller_id INT, -- FK
  order_status VARCHAR(15),
  CONSTRAINT orders_fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT orders_fk_sellers FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

-- order_items_table

CREATE TABLE order_items
( 
  order_item_id INT PRIMARY KEY,
  order_id INT, -- FK 
  product_id INT, -- FK
  quantity INT,
  price_per_unit FLOAT,
  CONSTRAINT order_items_fk_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT order_items_fk_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- payments_table

CREATE TABLE payments
(
  payment_id INT PRIMARY KEY,
  order_id INT, -- FK
  payment_date DATE,
  payment_status VARCHAR(20),
  CONSTRAINT payments_fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- shipping_table

CREATE TABLE shipping
(
  shipping_id INT PRIMARY KEY,
  order_id INT, -- FK
  shipping_date DATE,
  return_date DATE,
  shipping_providers VARCHAR(10),
  delivery_status VARCHAR(20),
  CONSTRAINT shipping_fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
)

-- inventory_table

CREATE TABLE inventory 
(
  inventory_id INT PRIMARY KEY,
  product_id INT, -- FK
  stock INT,
  warehouse_id INT,
  last_stock_date DATE,
  CONSTRAINT inventory_fk_products FOREIGN KEY (product_id) REFERENCES products(product_id)
);


----- EDA -----

SELECT * FROM category;
SELECT * FROM customers;
SELECT * FROM sellers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM payments;
SELECT * FROM shipping;
SELECT * FROM inventory;


SELECT DISTINCT(payment_status) FROM payments;
SELECT * FROM shipping WHERE return_date IS NOT NULL; 
-- sample: order_id: 6747
SELECT * FROM orders WHERE order_id = 6747;
SELECT * FROM payments WHERE order_id = 6747;
SELECT * FROM shipping WHERE return_date IS NULL; -- 18301 delivered successfully