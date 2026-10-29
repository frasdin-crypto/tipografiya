-- Импорт CSV в уже созданные таблицы.
-- Запускать из корня репозитория:
--   sqlite3 printshop.db ".read import.sql"

PRAGMA foreign_keys = OFF;

.mode csv
.import --skip 1 data/clients.csv clients
.import --skip 1 data/employees.csv employees
.import --skip 1 data/paper_types.csv paper_types
.import --skip 1 data/products.csv products
.import --skip 1 data/materials.csv materials
.import --skip 1 data/product_materials.csv product_materials
.import --skip 1 data/orders.csv orders
.import --skip 1 data/order_items.csv order_items

PRAGMA foreign_keys = ON;
