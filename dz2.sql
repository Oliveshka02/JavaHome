
-- ============================================================
-- 1. АССОРТИМЕНТ: Виды напитков (названия на 2 языках, один — английский)
-- ============================================================
CREATE TABLE beverages (
    id SERIAL PRIMARY KEY,
    name_uk VARCHAR(100) NOT NULL,        -- Название украинским
    name_en VARCHAR(100) NOT NULL,        -- Название английским
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. АССОРТИМЕНТ: Виды десертов (названия на 2 языках, один — английский)
-- ============================================================
CREATE TABLE desserts (
    id SERIAL PRIMARY KEY,
    name_uk VARCHAR(100) NOT NULL,        -- Название украинским
    name_en VARCHAR(100) NOT NULL,        -- Название английским
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. ПЕРСОНАЛ КАВ'ЯРНІ
-- ============================================================
CREATE TABLE staff_positions (
    id SERIAL PRIMARY KEY,
    position_name VARCHAR(50) NOT NULL UNIQUE
);

-- Заполняем должности
INSERT INTO staff_positions (position_name) VALUES 
    ('Бариста'), ('Офіціант'), ('Кондитер');

CREATE TABLE staff (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,      -- ПІБ
    phone VARCHAR(20),                    -- Контактний телефон
    address TEXT,                         -- Контактна поточна адреса
    position_id INTEGER NOT NULL REFERENCES staff_positions(id),
    hire_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT TRUE,       -- FALSE если уволен
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 4. КЛІЄНТИ
-- ============================================================
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,      -- ПІБ
    birth_date DATE,                      -- Дата народження
    phone VARCHAR(20),                    -- Контактний телефон
    address TEXT,                         -- Контактна поточна адреса
    discount_percent DECIMAL(5, 2) DEFAULT 0, -- Знижка (%)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 5. ГРАФІК РОБОТИ ПЕРСОНАЛУ
-- ============================================================
CREATE TABLE work_schedule (
    id SERIAL PRIMARY KEY,
    staff_id INTEGER NOT NULL REFERENCES staff(id),
    work_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(staff_id, work_date)           -- Один сотрудник — одна смена в день
);

-- ============================================================
-- 6. ЗАМОВЛЕННЯ
-- ============================================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    staff_id INTEGER NOT NULL REFERENCES staff(id),  -- Официант/бариста, принявший заказ
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active'   -- active, completed, cancelled
);

-- Детали заказа: напитки
CREATE TABLE order_beverages (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    beverage_id INTEGER NOT NULL REFERENCES beverages(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,   -- Цена на момент заказа
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- Детали заказа: десерты
CREATE TABLE order_desserts (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    dessert_id INTEGER NOT NULL REFERENCES desserts(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,   -- Цена на момент заказа
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- ============================================================
-- ТРИГГЕР: Автоматический пересчет суммы заказа
-- ============================================================
CREATE OR REPLACE FUNCTION recalculate_order_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders 
    SET total_amount = (
        SELECT COALESCE(SUM(subtotal), 0) 
        FROM (
            SELECT subtotal FROM order_beverages WHERE order_id = NEW.order_id
            UNION ALL
            SELECT subtotal FROM order_desserts WHERE order_id = NEW.order_id
        ) AS items
    )
    WHERE id = NEW.order_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recalc_total_beverages
AFTER INSERT OR UPDATE OR DELETE ON order_beverages
FOR EACH ROW EXECUTE FUNCTION recalculate_order_total();

CREATE TRIGGER trg_recalc_total_desserts
AFTER INSERT OR UPDATE OR DELETE ON order_desserts
FOR EACH ROW EXECUTE FUNCTION recalculate_order_total();


-- ============================================================
-- ЗАДАНИЕ 2: ДОБАВЛЕНИЕ ДАННЫХ
-- ============================================================

-- 1. Добавление новой позиции в ассортимент (новый напиток)
INSERT INTO beverages (name_uk, name_en, description, price) 
VALUES ('Раф-кава', 'Raf Coffee', 'Кава з вершками та ваніллю', 70.00);

-- 2. Добавление информации о новом баристе
INSERT INTO staff (full_name, phone, address, position_id) 
VALUES ('Бондаренко Сергій Миколайович', '+380955556677', 'вул. Драгоманова, 12, Київ', 1);

-- 3. Добавление информации о новом кондитере
INSERT INTO staff (full_name, phone, address, position_id) 
VALUES ('Гриценко Ольга Іванівна', '+380966667788', 'вул. Тургенєвська, 7, Київ', 3);

-- 4. Добавление информации о новом клиенте
INSERT INTO customers (full_name, birth_date, phone, address, discount_percent) 
VALUES ('Коцюбинський Михайло Михайлович', '1988-12-01', '+380977778899', 'вул. Лютеранська, 3, Київ', 7.50);

-- 5. Добавление нового заказа кофе
-- Сначала создаем заказ
INSERT INTO orders (customer_id, staff_id, status) 
VALUES (2, 1, 'active');
-- Добавляем кофе в заказ (order_id будет зависеть от предыдущего INSERT)
INSERT INTO order_beverages (order_id, beverage_id, quantity, unit_price) 
VALUES (
    (SELECT MAX(id) FROM orders WHERE customer_id = 2), 
    1, 1, 45.00
);

-- 6. Добавление нового заказа десерта
-- Создаем заказ
INSERT INTO orders (customer_id, staff_id, status) 
VALUES (3, 2, 'active');
-- Добавляем десерт в заказ
INSERT INTO order_desserts (order_id, dessert_id, quantity, unit_price) 
VALUES (
    (SELECT MAX(id) FROM orders WHERE customer_id = 3), 
    4, 3, 40.00
);

-- 7. Добавление графика работы на ближайший понедельник
INSERT INTO work_schedule (staff_id, work_date, start_time, end_time) 
VALUES 
    (1, DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days', '08:00', '16:00'),
    (2, DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days', '10:00', '18:00'),
    (4, DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days', '12:00', '20:00');

-- 8. Добавление нового вида кофе
INSERT INTO beverages (name_uk, name_en, description, price) 
VALUES ('Флет-вайт', 'Flat White', 'Кава з мікропінкою', 65.00);


-- ============================================================
-- ЗАДАНИЕ 3: ИЗМЕНЕНИЕ ДАННЫХ
-- ============================================================

-- 1. Изменить цену на конкретный вид кофе (например, Латте, id=3)
UPDATE beverages 
SET price = 65.00 
WHERE id = 3;

-- 2. Изменить контактный телефон и адрес кондитера (id=3 — Коваленко)
UPDATE staff 
SET phone = '+380994445566', 
    address = 'вул. Нова, 100, Київ' 
WHERE id = 3;

-- 3. Изменить контактный телефон баристы (id=1 — Петренко)
UPDATE staff 
SET phone = '+380501111111' 
WHERE id = 1;

-- 4. Изменить процент скидки конкретного клиента (id=1 — Шевченко)
UPDATE customers 
SET discount_percent = 15.00 
WHERE id = 1;

-- 5. Изменить название уже существующего вида кофе (id=2 — Капучино)
UPDATE beverages 
SET name_uk = 'Капучіно класичне', 
    name_en = 'Classic Cappuccino' 
WHERE id = 2;

-- 6. Изменить название уже существующего десерта (id=2 — Чизкейк)
UPDATE desserts 
SET name_uk = 'Нью-Йорк чізкейк', 
    name_en = 'New York Cheesecake' 
WHERE id = 2;

-- ============================================================
-- ЗАДАНИЕ 4: УДАЛЕНИЕ ДАННЫХ
-- ============================================================

-- 1. Удалить информацию о конкретном десерте (id=4 — Макарон)
DELETE FROM order_desserts WHERE dessert_id = 4;
DELETE FROM desserts WHERE id = 4;

-- 2. Удалить информацию о конкретном официанте по причине увольнения (id=2 — Сидоренко)
UPDATE staff 
SET is_active = FALSE 
WHERE id = 2 AND position_id = (SELECT id FROM staff_positions WHERE position_name = 'Офіціант');


-- 3. Удалить информацию о конкретном баристе по причине увольнения (id=4 — Мельник)
UPDATE staff 
SET is_active = FALSE 
WHERE id = 4 AND position_id = (SELECT id FROM staff_positions WHERE position_name = 'Бариста');

-- 4. Удалить информацию о конкретном клиенте (id=3 — Леся Українка)
DELETE FROM order_beverages WHERE order_id IN (SELECT id FROM orders WHERE customer_id = 3);
DELETE FROM order_desserts WHERE order_id IN (SELECT id FROM orders WHERE customer_id = 3);
DELETE FROM orders WHERE customer_id = 3;
DELETE FROM customers WHERE id = 3;

-- 5. Удалить заказ конкретного десерта (например, все заказы Тирамісу id=1)
DELETE FROM order_desserts WHERE dessert_id = 1;

-- 6. Удалить конкретное заказ (id=1)
DELETE FROM order_beverages WHERE order_id = 1;
DELETE FROM order_desserts WHERE order_id = 1;
DELETE FROM orders WHERE id = 1;




-- ============================================================
-- ЗАДАНИЕ 5: ВЫБОРКА ДАННЫХ
-- ============================================================

-- 1. Показать все напитки
SELECT 
    b.id,
    b.name_uk AS "Назва (укр.)",
    b.name_en AS "Назва (англ.)",
    b.description AS "Опис",
    b.price AS "Ціна (грн)",
    b.is_active AS "Активний"
FROM beverages b
ORDER BY b.id;

-- 2. Показать все десерты
SELECT 
    d.id,
    d.name_uk AS "Назва (укр.)",
    d.name_en AS "Назва (англ.)",
    d.description AS "Опис",
    d.price AS "Ціна (грн)",
    d.is_active AS "Активний"
FROM desserts d
ORDER BY d.id;

-- 3. Показать информацию о всех баристах
SELECT 
    s.id,
    s.full_name AS "ПІБ",
    s.phone AS "Телефон",
    s.address AS "Адреса",
    s.hire_date AS "Дата прийому",
    s.is_active AS "Активний"
FROM staff s
JOIN staff_positions sp ON s.position_id = sp.id
WHERE sp.position_name = 'Бариста'
ORDER BY s.id;

-- 4. Показать информацию о всех официантах
SELECT 
    s.id,
    s.full_name AS "ПІБ",
    s.phone AS "Телефон",
    s.address AS "Адреса",
    s.hire_date AS "Дата прийому",
    s.is_active AS "Активний"
FROM staff s
JOIN staff_positions sp ON s.position_id = sp.id
WHERE sp.position_name = 'Офіціант'
ORDER BY s.id;

-- 5. Показать все заказы конкретного десерта (id=1 — Тирамісу)
SELECT 
    o.id AS "№ замовлення",
    o.order_date AS "Дата",
    c.full_name AS "Клієнт",
    s.full_name AS "Персонал",
    od.quantity AS "Кількість",
    od.unit_price AS "Ціна за од.",
    od.subtotal AS "Сума",
    o.status AS "Статус"
FROM order_desserts od
JOIN orders o ON od.order_id = o.id
JOIN desserts d ON od.dessert_id = d.id
LEFT JOIN customers c ON o.customer_id = c.id
JOIN staff s ON o.staff_id = s.id
WHERE d.id = 1
ORDER BY o.order_date DESC;

-- 6. Показать все заказы конкретного официанта (id=2 — Сидоренко)
SELECT 
    o.id AS "№ замовлення",
    o.order_date AS "Дата",
    c.full_name AS "Клієнт",
    o.total_amount AS "Загальна сума",
    o.status AS "Статус",
    (SELECT COUNT(*) FROM order_beverages WHERE order_id = o.id) AS "К-сть напоїв",
    (SELECT COUNT(*) FROM order_desserts WHERE order_id = o.id) AS "К-сть десертів"
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
JOIN staff s ON o.staff_id = s.id
WHERE s.id = 2
ORDER BY o.order_date DESC;

-- 7. Показать все заказы конкретного клиента (id=1 — Шевченко)
SELECT 
    o.id AS "№ замовлення",
    o.order_date AS "Дата",
    s.full_name AS "Оформив",
    o.total_amount AS "Загальна сума",
    o.status AS "Статус"
FROM orders o
JOIN staff s ON o.staff_id = s.id
WHERE o.customer_id = 1
ORDER BY o.order_date DESC;

-- Детализация заказа клиента (все позиции)
SELECT 
    o.id AS "№ замовлення",
    'Напій' AS "Тип",
    b.name_uk AS "Назва",
    ob.quantity AS "Кількість",
    ob.unit_price AS "Ціна",
    ob.subtotal AS "Сума"
FROM orders o
JOIN order_beverages ob ON o.id = ob.order_id
JOIN beverages b ON ob.beverage_id = b.id
WHERE o.customer_id = 1

UNION ALL

SELECT 
    o.id AS "№ замовлення",
    'Десерт' AS "Тип",
    d.name_uk AS "Назва",
    od.quantity AS "Кількість",
    od.unit_price AS "Ціна",
    od.subtotal AS "Сума"
FROM orders o
JOIN order_desserts od ON o.id = od.order_id
JOIN desserts d ON od.dessert_id = d.id
WHERE o.customer_id = 1

ORDER BY "№ замовлення", "Тип";


-- ============================================================
-- ЗАДАНИЕ 6: ДОПОЛНИТЕЛЬНЫЕ ЗАПРОСЫ
-- ============================================================

-- 6.1 Показать информацию о клиентах, которые заказывали напитки сегодня.
--     Кроме информации о клиенте, нужно показать информацию о баристе, который делал напиток
SELECT DISTINCT
    c.id AS "ID клиента",
    c.full_name AS "ФИО клиента",
    c.phone AS "Телефон клиента",
    c.address AS "Адрес клиента",
    c.discount_percent AS "Скидка (%)",
    b.id AS "ID баристы",
    b.full_name AS "ФИО баристы",
    b.phone AS "Телефон баристы",
    bev.name_uk AS "Напиток",
    ob.quantity AS "Количество",
    ob.subtotal AS "Сумма"
FROM customers c
JOIN orders o ON c.id = o.customer_id
JOIN order_beverages ob ON o.id = ob.order_id
JOIN beverages bev ON ob.beverage_id = bev.id
JOIN staff b ON o.staff_id = b.id
JOIN staff_positions sp ON b.position_id = sp.id
WHERE DATE(o.order_date) = CURRENT_DATE
  AND sp.position_name = 'Бариста'
ORDER BY c.full_name, bev.name_uk;

-- 6.2 Показать среднюю сумму заказа в конкретный день (для сегодня)
SELECT 
    DATE(o.order_date) AS "Дата",
    COUNT(o.id) AS "Количество заказов",
    ROUND(AVG(o.total_amount), 2) AS "Средняя сумма (грн)",
    ROUND(SUM(o.total_amount), 2) AS "Общая сумма (грн)"
FROM orders o
WHERE DATE(o.order_date) = CURRENT_DATE
GROUP BY DATE(o.order_date);

-- 6.3 Показать максимальную сумму заказа в конкретную дату (для сегодня)
SELECT 
    DATE(o.order_date) AS "Дата",
    MAX(o.total_amount) AS "Максимальная сумма (грн)"
FROM orders o
WHERE DATE(o.order_date) = CURRENT_DATE
GROUP BY DATE(o.order_date);

-- 6.4 Показать клиента, который сделал максимальную сумму заказа в конкретную дату (для сегодня)
WITH max_order AS (
    SELECT MAX(total_amount) AS max_amount
    FROM orders
    WHERE DATE(order_date) = CURRENT_DATE
)
SELECT 
    c.id AS "ID клиента",
    c.full_name AS "ФИО клиента",
    c.phone AS "Телефон",
    c.address AS "Адрес",
    c.discount_percent AS "Скидка (%)",
    o.id AS "№ заказа",
    o.order_date AS "Дата заказа",
    o.total_amount AS "Сумма заказа (грн)",
    s.full_name AS "Оформил"
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN staff s ON o.staff_id = s.id
CROSS JOIN max_order
WHERE DATE(o.order_date) = CURRENT_DATE
  AND o.total_amount = max_order.max_amount;

-- 6.5 Показать расписание работы для всех работников кофейни на неделю
SELECT 
    ws.work_date AS "Дата",
    TO_CHAR(ws.work_date, 'Day') AS "День недели",
    s.id AS "ID работника",
    s.full_name AS "ФИО",
    sp.position_name AS "Должность",
    ws.start_time AS "Начало",
    ws.end_time AS "Конец",
    (ws.end_time - ws.start_time) AS "Длительность смены"
FROM work_schedule ws
JOIN staff s ON ws.staff_id = s.id
JOIN staff_positions sp ON s.position_id = sp.id
WHERE ws.work_date >= DATE_TRUNC('week', CURRENT_DATE)
  AND ws.work_date < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days'
ORDER BY ws.work_date, ws.start_time, s.full_name;