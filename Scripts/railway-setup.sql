-- Railway PostgreSQL Setup Script
-- Run this after connecting to your Railway PostgreSQL database

-- Create schema
CREATE SCHEMA IF NOT EXISTS dairy;

-- Create tables
CREATE TABLE IF NOT EXISTS dairy.farmer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    contact VARCHAR(15),
    village VARCHAR(50),
    bank_account VARCHAR(20),
    ifsc_code VARCHAR(11),
    aadhar_number VARCHAR(12),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dairy.customer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(15),
    address TEXT,
    gst_number VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dairy.milk_collection (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    qty_ltr DECIMAL(10,2) NOT NULL,
    fat_pct DECIMAL(5,2) NOT NULL,
    price_per_ltr DECIMAL(10,2) NOT NULL,
    due_amt DECIMAL(10,2) NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dairy.sales (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES dairy.customer(id),
    qty_ltr DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    paid_amt DECIMAL(10,2) NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dairy.payment_farmer (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'Cash',
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO dairy.farmer (name, code, contact, village) VALUES 
('Ramesh Kumar', 'F001', '9876543210', 'Village A'),
('Suresh Patel', 'F002', '9876543211', 'Village B')
ON CONFLICT (code) DO NOTHING;

INSERT INTO dairy.customer (name, contact, address) VALUES 
('Local Store', '9876543220', 'Main Market'),
('Dairy Shop', '9876543221', 'City Center')
ON CONFLICT DO NOTHING;