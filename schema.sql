-- Типография «Печатный двор»
-- SQLite DDL, 3НФ

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS product_materials;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS materials;
DROP TABLE IF EXISTS paper_types;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS clients;

CREATE TABLE clients (
    client_id      INTEGER PRIMARY KEY,
    company_name   TEXT    NOT NULL,
    contact_person TEXT    NOT NULL,
    phone          TEXT    NOT NULL,
    email          TEXT,
    inn            TEXT    UNIQUE,
    address        TEXT
);

CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    full_name   TEXT    NOT NULL,
    position    TEXT    NOT NULL,
    phone       TEXT,
    hire_date   TEXT    NOT NULL
);

CREATE TABLE paper_types (
    paper_type_id  INTEGER PRIMARY KEY,
    name           TEXT    NOT NULL UNIQUE,
    density_gsm    INTEGER NOT NULL CHECK (density_gsm > 0),
    format         TEXT    NOT NULL,
    price_per_sheet REAL   NOT NULL CHECK (price_per_sheet >= 0)
);

CREATE TABLE products (
    product_id             INTEGER PRIMARY KEY,
    name                   TEXT    NOT NULL,
    category               TEXT    NOT NULL,
    paper_type_id          INTEGER NOT NULL,
    production_time_hours  INTEGER NOT NULL CHECK (production_time_hours > 0),
    base_price             REAL    NOT NULL CHECK (base_price >= 0),
    FOREIGN KEY (paper_type_id) REFERENCES paper_types(paper_type_id)
);

CREATE TABLE materials (
    material_id INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL,
    unit        TEXT    NOT NULL,
    stock_qty   REAL    NOT NULL CHECK (stock_qty >= 0),
    min_stock   REAL    NOT NULL CHECK (min_stock >= 0),
    unit_price  REAL    NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE product_materials (
    product_id   INTEGER NOT NULL,
    material_id  INTEGER NOT NULL,
    qty_per_unit REAL    NOT NULL CHECK (qty_per_unit > 0),
    PRIMARY KEY (product_id, material_id),
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    FOREIGN KEY (material_id) REFERENCES materials(material_id)
);

CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY,
    client_id   INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    order_date  TEXT    NOT NULL,
    due_date    TEXT    NOT NULL,
    status      TEXT    NOT NULL CHECK (status IN ('новый', 'в печати', 'готов', 'выдан', 'отменён')),
    notes       TEXT,
    FOREIGN KEY (client_id)   REFERENCES clients(client_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL,
    product_id    INTEGER NOT NULL,
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    color_mode    TEXT    NOT NULL CHECK (color_mode IN ('CMYK', 'ч/б')),
    unit_price    REAL    NOT NULL CHECK (unit_price >= 0),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE INDEX idx_orders_client ON orders(client_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
