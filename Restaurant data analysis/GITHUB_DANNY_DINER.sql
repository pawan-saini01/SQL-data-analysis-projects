create database danny_diner
use danny_diner

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');



  SELECT * FROM members
  SELECT * FROM menu
  SELECT * FROM sales


  --Each of the following case study questions can be answered using a single SQL statement:

--What is the total amount each customer spent at the restaurant?

SELECT CUSTOMER_ID, SUM(price) AS SPENT
FROM SALES S INNER JOIN menu M 
ON S.product_id = M.product_id
GROUP BY customer_id

--How many days has each customer visited the restaurant?

SELECT CUSTOMER_ID, COUNT(DISTINCT ORDER_DATE) AS VISITS
FROM sales
GROUP BY customer_id

--What was the first item from the menu purchased by each customer?

WITH CUSTOMER_FIRST_ORDER AS 
(
SELECT CUSTOMER_ID, ORDER_DATE,PRODUCT_NAME, ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE) AS RANK1
FROM SALES S INNER JOIN MENU M
ON S.product_id = M.product_id) 
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM CUSTOMER_FIRST_ORDER 
WHERE RANK1 = 1

--What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 PRODUCT_NAME, COUNT(S.product_id) AS TOTAL_COUNT
FROM MENU M INNER JOIN sales S
ON M.product_id = S.product_id
GROUP BY product_name
ORDER BY 2 DESC

--Which item was the most popular for each customer?

WITH FAV_ITEM AS
(
SELECT CUSTOMER_ID, PRODUCT_NAME, COUNT(M.PRODUCT_ID) AS TOTAL, DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY COUNT(M.PRODUCT_ID) DESC) AS RNK
FROM SALES S INNER JOIN MENU M
ON S.product_id = M.product_id
GROUP BY customer_id, product_name)
SELECT CUSTOMER_ID, PRODUCT_NAME, TOTAL
FROM FAV_ITEM
WHERE RNK = 1

--Which item was purchased first by the customer after they became a member?

SELECT A. CUSTOMER_ID, A. product_name, A.ORDER_DATE, A.join_date
FROM
(SELECT S. CUSTOMER_ID, S.order_date, M.join_date,C. PRODUCT_NAME, ROW_NUMBER() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE) AS FIRST_ORDER
FROM sales S 
INNER JOIN members M ON S.customer_id = M.customer_id 
INNER JOIN MENU C ON S.PRODUCT_ID = C.product_id AND S.order_date >= M.join_date ) A
WHERE FIRST_ORDER = 1



--Which item was purchased just before the customer became a member?


SELECT A. CUSTOMER_ID, A. product_name, A.ORDER_DATE, A.join_date
FROM
(SELECT S. CUSTOMER_ID, S.order_date, M.join_date,C. PRODUCT_NAME, ROW_NUMBER() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE DESC) AS FIRST_ORDER
FROM sales S 
INNER JOIN members M ON S.customer_id = M.customer_id 
INNER JOIN MENU C ON S.PRODUCT_ID = C.product_id AND S.order_date < M.join_date ) A
WHERE FIRST_ORDER = 1

--What is the total items and amount spent for each member before they became a member?

SELECT S. CUSTOMER_ID,  COUNT(S.PRODUCT_ID)AS TOTAL_ITEMS, SUM(C. PRICE)AS AMOUNT_SPENT
FROM sales S 
INNER JOIN members M ON S.customer_id = M.customer_id 
INNER JOIN MENU C ON S.PRODUCT_ID = C.product_id AND S.order_date < M. join_date
GROUP BY S.customer_id

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT S. CUSTOMER_ID, SUM(CASE WHEN C.product_name = 'SUSHI' THEN C.price * 20 ELSE C.price * 10 END) AS POINTS
FROM sales S 
INNER JOIN MENU C ON S.PRODUCT_ID = C.product_id 
GROUP BY S.customer_id


--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT S. CUSTOMER_ID, SUM(CASE WHEN S. ORDER_DATE BETWEEN M.join_date AND DATEADD(DAY, 6 , M.JOIN_DATE) THEN C.PRICE * 20
								WHEN C.product_name = 'SUSHI' THEN C.price * 20 ELSE C.price * 10 END) AS POINTS
FROM sales S 
INNER JOIN MENU C ON S.PRODUCT_ID = C.product_id 
INNER JOIN members M ON S.customer_id = M.customer_id AND S.order_date <= EOMONTH('2021-01-31')
GROUP BY S.customer_id