-- Dairy Milk Collection & Sales Management System
-- PostgreSQL DDL Script
-- Created: 2025-08-18

-- SCHEMA: dairy
CREATE SCHEMA IF NOT EXISTS dairy;
SET search_path TO dairy;

-- Branches
CREATE TABLE branch (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    contact VARCHAR(50)
);

-- Employees
CREATE TABLE employee (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    branch_id INT REFERENCES branch(id),
    role VARCHAR(30) NOT NULL -- Admin, CollectionBoy
);

-- Collection Boys (role on employee)
-- Farmers
CREATE TABLE farmer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    contact VARCHAR(50) NOT NULL,
    bank_id INT,
    branch_id INT REFERENCES branch(id)
);

-- Customers
CREATE TABLE customer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    branch_id INT REFERENCES branch(id)
);

-- Banks
CREATE TABLE bank (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Farmer ↔ Bank
ALTER TABLE farmer ADD CONSTRAINT fk_farmer_bank FOREIGN KEY (bank_id) REFERENCES bank(id);

-- Expense Categories
CREATE TABLE expense_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Expenses
CREATE TABLE expense (
    id SERIAL PRIMARY KEY,
    category_id INT REFERENCES expense_category(id),
    branch_id INT REFERENCES branch(id),
    amount NUMERIC(12,2) NOT NULL,
    date DATE NOT NULL,
    notes TEXT,
    created_by INT REFERENCES employee(id)
);

-- Shifts
CREATE TABLE shift (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    start_time TIME,
    end_time TIME
);

-- Sell Rates
CREATE TABLE sell_rate (
    id SERIAL PRIMARY KEY,
    item_id INT,
    rate NUMERIC(8,2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    branch_id INT REFERENCES branch(id)
);

-- Rate Charts
CREATE TABLE rate_chart (
    id SERIAL PRIMARY KEY,
    milk_type VARCHAR(30) NOT NULL,
    shift_id INT REFERENCES shift(id),
    rate NUMERIC(8,2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    file_ref VARCHAR(255)
);

-- Items
CREATE TABLE item (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Product Conversion
CREATE TABLE product_conversion (
    id SERIAL PRIMARY KEY,
    item_id INT REFERENCES item(id),
    milk_qty NUMERIC(8,2) NOT NULL,
    product_qty NUMERIC(8,2) NOT NULL
);

-- Milk Collection
CREATE TABLE milk_collection (
    id SERIAL PRIMARY KEY,
    farmer_id INT REFERENCES farmer(id),
    shift_id INT REFERENCES shift(id),
    date DATE NOT NULL,
    qty_ltr NUMERIC(8,2) NOT NULL CHECK (qty_ltr > 0 AND qty_ltr <= 999),
    fat_pct NUMERIC(4,2) NOT NULL CHECK (fat_pct >= 0 AND fat_pct <= 15),
    price_per_ltr NUMERIC(8,2) NOT NULL,
    due_amt NUMERIC(12,2) NOT NULL,
    notes TEXT,
    created_by INT REFERENCES employee(id),
    UNIQUE (farmer_id, shift_id, date)
);
CREATE INDEX idx_milk_collection_date_shift ON milk_collection(date, shift_id);
CREATE INDEX idx_milk_collection_farmer_date ON milk_collection(farmer_id, date);

-- Sales
CREATE TABLE sale (
    id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customer(id),
    shift_id INT REFERENCES shift(id),
    date DATE NOT NULL,
    qty_ltr NUMERIC(8,2) NOT NULL CHECK (qty_ltr > 0 AND qty_ltr <= 999),
    unit_price NUMERIC(8,2) NOT NULL,
    discount NUMERIC(8,2) DEFAULT 0,
    paid_amt NUMERIC(12,2) NOT NULL,
    due_amt NUMERIC(12,2) NOT NULL,
    created_by INT REFERENCES employee(id)
);
CREATE INDEX idx_sale_date_shift ON sale(date, shift_id);
CREATE INDEX idx_sale_customer_date ON sale(customer_id, date);

-- Payments (Customer)
CREATE TABLE payment_customer (
    id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customer(id),
    sale_id INT REFERENCES sale(id),
    amount NUMERIC(12,2) NOT NULL,
    date DATE NOT NULL,
    invoice_no VARCHAR(30) UNIQUE,
    pdf_path VARCHAR(255)
);

-- Payments (Farmer)
CREATE TABLE payment_farmer (
    id SERIAL PRIMARY KEY,
    farmer_id INT REFERENCES farmer(id),
    milk_collection_id INT REFERENCES milk_collection(id),
    amount NUMERIC(12,2) NOT NULL,
    date DATE NOT NULL,
    invoice_no VARCHAR(30) UNIQUE,
    pdf_path VARCHAR(255)
);

-- User Accounts
CREATE TABLE user_account (
    id SERIAL PRIMARY KEY,
    login VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL,
    person_ref INT,
    FOREIGN KEY (person_ref) REFERENCES employee(id)
);

-- Audit Log
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES user_account(id),
    action VARCHAR(100) NOT NULL,
    entity VARCHAR(50),
    entity_id INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

-- Settings
CREATE TABLE settings (
    id SERIAL PRIMARY KEY,
    system_name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    address TEXT NOT NULL
);

-- Sample Data
INSERT INTO branch (name, address, contact) VALUES ('Main Branch', '123 Dairy Lane', '9876543210');
INSERT INTO bank (name) VALUES ('State Bank of India'), ('Bank of Maharashtra');
INSERT INTO employee (name, contact, branch_id, role) VALUES ('Admin User', '9999999999', 1, 'Admin'), ('Collector One', '8888888888', 1, 'CollectionBoy');
INSERT INTO farmer (name, code, contact, bank_id, branch_id) VALUES ('Farmer A', 'F001', '7777777777', 1, 1), ('Farmer B', 'F002', '6666666666', 2, 1);
INSERT INTO customer (name, contact, branch_id) VALUES ('Customer X', '5555555555', 1), ('Customer Y', '4444444444', 1);
INSERT INTO expense_category (name) VALUES ('Transport'), ('Feed'), ('Maintenance');
INSERT INTO shift (name, start_time, end_time) VALUES ('Morning', '06:00', '10:00'), ('Evening', '16:00', '20:00');
INSERT INTO item (name) VALUES ('Milk'), ('Paneer'), ('Ghee');
INSERT INTO settings (system_name, contact, address) VALUES ('Dairy Management System', '9876543210', '123 Dairy Lane');

-- End of DDL
