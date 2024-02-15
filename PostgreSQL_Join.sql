-- Задание 1
-- Несмотря на то, что в данных значения по времени одинаковое, учтём и это
SELECT name 
FROM orders_new_3
LEFT JOIN customers_new_3 USING (customer_id)
WHERE (EXTRACT(EPOCH FROM orders_new_3.shipment_date::timestamptz) -
       EXTRACT(EPOCH FROM orders_new_3.order_date::timestamptz)) =
       (SELECT MAX(EXTRACT(EPOCH FROM shipment_date::timestamptz) -
       EXTRACT(EPOCH FROM order_date::timestamptz)) from orders_new_3)
limit 1

-- Задание 2
SELECT c.name, o.avg as average_time, o.sum as total_amount
FROM (
    SELECT customer_id, COUNT(*), avg(shipment_date::timestamptz - order_date::timestamptz), Sum(order_ammount)
    FROM orders_new_3
    GROUP BY customer_id
    ORDER BY count(*) DESC
    FETCH FIRST 1 ROWS WITH TIES
    ) o JOIN customers_new_3 c ON o.customer_id = c.customer_id
ORDER BY total_amount DESC

-- Задание 3
-- В заказах, доставленных больше 5 дней будем учитывать не только Approved, но и Сancel(отмененные)
SELECT DISTINCT name,
 (SELECT COUNT(*) FROM orders_new_3
  WHERE (EXTRACT(EPOCH FROM orders_new_3.shipment_date::timestamptz) -
         EXTRACT(EPOCH FROM orders_new_3.order_date::timestamptz)) > 432000 and
         customers_new_3.customer_id = orders_new_3.customer_id) count_delay, 
 (SELECT COUNT(*) FROM orders_new_3
  WHERE order_status = 'Cancel' and customers_new_3.customer_id = orders_new_3.customer_id) count_cancel,
  (SELECT SUM(order_ammount) FROM orders_new_3
  WHERE ((EXTRACT(EPOCH FROM orders_new_3.shipment_date::timestamptz) -
         EXTRACT(EPOCH FROM orders_new_3.order_date::timestamptz)) > 432000 or order_status = 'Cancel') and
         customers_new_3.customer_id = orders_new_3.customer_id) amount
FROM customers_new_3
ORDER BY amount DESC NULLS LAST

-- Задание 4
-- В данном задании в пунктах 4.2 и 4.3 можно находить самые дорогие продукты, что по product_id,
-- что по product_name. Сделаем оба варианта
-- Вариант задания с группировкой по product_id
with emp as (SELECT product_category, Max(fund) from 
(SELECT product_category,product_name,
sum(order_ammount) over (partition by product_id) as fund
FROM orders_2
LEFT JOIN products_3 USING (product_id))
GROUP by product_category
ORDER by Max(fund) DESC),
amp as (SELECT product_category, product_name FROM emp
LEFT JOIN 
(SELECT product_name, max(fund) from
(SELECT product_name, 
sum(order_ammount) over (partition by product_id) as fund
FROM orders_2
LEFT JOIN products_3 USING (product_id))
GROUP by product_name)c on emp.max=c.max),
e AS (SELECT product_category, SUM(order_ammount)
FROM products_3
LEFT JOIN orders_2 USING (product_id)
GROUP by product_category)

SELECT product_category, sum as amount_category,
(SELECT product_category as category_max_product FROM emp
LIMIT 1),
amp.product_name as max_product_in_category
FROM e
LEFT JOIN amp USING (product_category)

-- Вариант с группировкой по product_name
with emp as (SELECT product_category, Max(fund) from
(SELECT product_category,product_name,
sum(order_ammount) over (partition by product_name) as fund
FROM orders_2
LEFT JOIN products_3 USING (product_id))
GROUP by product_category
ORDER by Max(fund) DESC), 
amp as (SELECT product_category, product_name FROM emp
LEFT JOIN 
(SELECT product_name, SUM(order_ammount) FROM products_3
LEFT JOIN orders_2 USING (product_id)
GROUP by product_name
ORDER BY SUM(order_ammount) DESC)c on emp.max=c.sum),
e AS (SELECT product_category, SUM(order_ammount)
FROM products_3
LEFT JOIN orders_2 USING (product_id)
GROUP by product_category)

SELECT product_category, sum as amount_category,
(SELECT product_category as category_max_product FROM emp
LIMIT 1),
amp.product_name as max_product_in_category
FROM e
LEFT JOIN amp USING (product_category)