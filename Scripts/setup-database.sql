CREATE SCHEMA IF NOT EXISTS dairy;
SET search_path TO dairy;

CREATE TABLE IF NOT EXISTS branch (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    contact VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS employee (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    branch_id INTEGER REFERENCES branch(id),
    role VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS farmer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    contact VARCHAR(50) NOT NULL,
    bank_id INTEGER,
    branch_id INTEGER REFERENCES branch(id)
);

CREATE TABLE IF NOT EXISTS customer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    branch_id INTEGER REFERENCES branch(id)
);

CREATE TABLE IF NOT EXISTS bank (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS shift (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    start_time TIME,
    end_time TIME
);

CREATE TABLE IF NOT EXISTS milk_collection (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES farmer(id),
    shift_id INTEGER REFERENCES shift(id),
    date DATE NOT NULL,
    qty_ltr NUMERIC(8,2) NOT NULL,
    fat_pct NUMERIC(4,2) NOT NULL,
    price_per_ltr NUMERIC(8,2) NOT NULL,
    due_amt NUMERIC(12,2) NOT NULL,
    notes TEXT,
    created_by INTEGER REFERENCES employee(id)
);

CREATE TABLE IF NOT EXISTS sale (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customer(id),
    shift_id INTEGER REFERENCES shift(id),
    date DATE NOT NULL,
    qty_ltr NUMERIC(8,2) NOT NULL,
    unit_price NUMERIC(8,2) NOT NULL,
    discount NUMERIC(8,2) DEFAULT 0,
    paid_amt NUMERIC(12,2) NOT NULL,
    due_amt NUMERIC(12,2) NOT NULL,
    created_by INTEGER REFERENCES employee(id)
);

CREATE TABLE IF NOT EXISTS payment_farmer (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES farmer(id),
    milk_collection_id INTEGER REFERENCES milk_collection(id),
    amount NUMERIC(12,2) NOT NULL,
    date DATE NOT NULL,
    invoice_no VARCHAR(30) UNIQUE,
    pdf_path VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS payment_customer (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customer(id),
    sale_id INTEGER REFERENCES sale(id),
    amount NUMERIC(12,2) NOT NULL,
    date DATE NOT NULL,
    invoice_no VARCHAR(30) UNIQUE,
    pdf_path VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    action VARCHAR(100) NOT NULL,
    entity VARCHAR(50),
    entity_id INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

INSERT INTO branch (name, address, contact) VALUES ('Main Branch', '123 Dairy Lane', '9876543210') ON CONFLICT DO NOTHING;
INSERT INTO bank (name) VALUES ('State Bank of India') ON CONFLICT DO NOTHING;
INSERT INTO employee (name, contact, branch_id, role) VALUES ('Admin User', '9999999999', 1, 'Admin') ON CONFLICT DO NOTHING;
INSERT INTO farmer (name, code, contact, bank_id, branch_id) VALUES ('Farmer A', 'F001', '7777777777', 1, 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO customer (name, contact, branch_id) VALUES ('Customer X', '5555555555', 1) ON CONFLICT DO NOTHING;
INSERT INTO shift (name, start_time, end_time) VALUES ('Morning', '06:00', '10:00') ON CONFLICT DO NOTHING;