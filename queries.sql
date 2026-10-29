-- 15 SQL-запросов по БД типографии
-- Запуск: sqlite3 printshop.db ".read queries.sql"

.headers on
.mode column

-- 1. Список клиентов
SELECT client_id, company_name, contact_person, phone
FROM clients
ORDER BY company_name;

-- 2. Заказы с именами клиентов и менеджеров (JOIN)
SELECT o.order_id,
       c.company_name,
       e.full_name AS manager,
       o.order_date,
       o.status
FROM orders o
JOIN clients c   ON c.client_id = o.client_id
JOIN employees e ON e.employee_id = o.employee_id
ORDER BY o.order_date;

-- 3. Сумма каждого заказа (агрегат + JOIN)
SELECT o.order_id,
       c.company_name,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS order_sum
FROM orders o
JOIN clients c      ON c.client_id = o.client_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, c.company_name
ORDER BY order_sum DESC;

-- 4. Продукция дороже средней базовой цены (подзапрос)
SELECT product_id, name, base_price
FROM products
WHERE base_price > (SELECT AVG(base_price) FROM products)
ORDER BY base_price DESC;

-- 5. Количество заказов по статусам
SELECT status, COUNT(*) AS orders_count
FROM orders
GROUP BY status
ORDER BY orders_count DESC;

-- 6. Менеджеры и число оформленных заказов
SELECT e.full_name,
       e.position,
       COUNT(o.order_id) AS orders_count
FROM employees e
LEFT JOIN orders o ON o.employee_id = e.employee_id
WHERE e.position = 'менеджер'
GROUP BY e.employee_id, e.full_name, e.position;

-- 7. Клиенты без заказов (LEFT JOIN)
SELECT c.client_id, c.company_name
FROM clients c
LEFT JOIN orders o ON o.client_id = c.client_id
WHERE o.order_id IS NULL;

-- 8. Топ продукции по проданному количеству
SELECT p.name,
       SUM(oi.quantity) AS total_qty,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id = oi.order_id
WHERE o.status <> 'отменён'
GROUP BY p.product_id, p.name
ORDER BY total_qty DESC;

-- 9. Заказы за октябрь 2026
SELECT order_id, client_id, order_date, status
FROM orders
WHERE order_date BETWEEN '2026-10-01' AND '2026-10-31'
ORDER BY order_date;

-- 10. Материалы ниже минимального остатка
SELECT name, unit, stock_qty, min_stock
FROM materials
WHERE stock_qty < min_stock;

-- 11. Средний чек по выданным заказам
SELECT ROUND(AVG(order_sum), 2) AS avg_issued_order
FROM (
    SELECT o.order_id, SUM(oi.quantity * oi.unit_price) AS order_sum
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'выдан'
    GROUP BY o.order_id
);

-- 12. Продукция на мелованной бумаге 130 г
SELECT p.name, p.category, pt.name AS paper, pt.density_gsm
FROM products p
JOIN paper_types pt ON pt.paper_type_id = p.paper_type_id
WHERE pt.paper_type_id = 1;

-- 13. Клиенты с более чем одним заказом (HAVING)
SELECT c.company_name, COUNT(o.order_id) AS orders_count
FROM clients c
JOIN orders o ON o.client_id = c.client_id
GROUP BY c.client_id, c.company_name
HAVING COUNT(o.order_id) > 1
ORDER BY orders_count DESC;

-- 14. Самая дорогая позиция в каждом заказе (коррелированный подзапрос)
SELECT o.order_id,
       p.name AS product_name,
       oi.quantity,
       oi.unit_price,
       (oi.quantity * oi.unit_price) AS line_sum
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE (oi.quantity * oi.unit_price) = (
    SELECT MAX(oi2.quantity * oi2.unit_price)
    FROM order_items oi2
    WHERE oi2.order_id = oi.order_id
)
ORDER BY o.order_id;

-- 15. Детализация заказа: клиент, бумага, материалы нормы
SELECT o.order_id,
       c.company_name,
       p.name AS product_name,
       pt.name AS paper,
       oi.quantity,
       oi.color_mode,
       GROUP_CONCAT(m.name || ' ' || (pm.qty_per_unit * oi.quantity) || ' ' || m.unit, '; ') AS materials_need
FROM orders o
JOIN clients c            ON c.client_id = o.client_id
JOIN order_items oi       ON oi.order_id = o.order_id
JOIN products p           ON p.product_id = oi.product_id
JOIN paper_types pt       ON pt.paper_type_id = p.paper_type_id
LEFT JOIN product_materials pm ON pm.product_id = p.product_id
LEFT JOIN materials m     ON m.material_id = pm.material_id
GROUP BY o.order_id, c.company_name, p.name, pt.name, oi.quantity, oi.color_mode, oi.order_item_id
ORDER BY o.order_id;
