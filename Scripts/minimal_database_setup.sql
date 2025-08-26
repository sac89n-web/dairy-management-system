-- Minimal database setup for Dairy Management System
-- Run this in PostgreSQL to create basic tables

-- Create database if not exists (run this separately as superuser)
-- CREATE DATABASE dairy_management;

-- Connect to dairy_management database and run the following:

-- Basic tables for the application to start
CREATE TABLE IF NOT EXISTS milk_collection (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    fat_percentage DECIMAL(5,2),
    snf_percentage DECIMAL(5,2),
    collection_date DATE NOT NULL DEFAULT CURRENT_DATE,
    collection_time TIME NOT NULL DEFAULT CURRENT_TIME,
    rate DECIMAL(10,2),
    amount DECIMAL(10,2),
    payment_status VARCHAR(20) DEFAULT 'Pending',
    payment_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sales (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    rate DECIMAL(10,2) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    sale_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment_customers (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method VARCHAR(50),
    reference_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment_farmers (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method VARCHAR(50),
    reference_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(10) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    user_id INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User management tables
CREATE TABLE IF NOT EXISTS user_master (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'User',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_otp (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin user
INSERT INTO user_master (mobile, name, role) 
VALUES ('8108891477', 'Admin', 'Admin')
ON CONFLICT (mobile) DO NOTHING;

-- Insert sample data for testing
INSERT INTO milk_collection (farmer_id, quantity, fat_percentage, snf_percentage, rate, amount) VALUES
(1, 10.5, 4.2, 8.5, 35.00, 367.50),
(2, 8.0, 3.8, 8.2, 33.00, 264.00),
(3, 12.0, 4.5, 9.0, 38.00, 456.00)
ON CONFLICT DO NOTHING;

INSERT INTO sales (customer_id, product_name, quantity, rate, amount) VALUES
(1, 'Fresh Milk', 5.0, 45.00, 225.00),
(2, 'Paneer', 2.0, 350.00, 700.00),
(3, 'Curd', 3.0, 60.00, 180.00)
ON CONFLICT DO NOTHING;

COMMIT;