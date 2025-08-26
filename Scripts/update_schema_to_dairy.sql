-- Update all table references to use lowercase postgres database and dairy schema
-- Run this script to update existing database structure

-- Create dairy schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS dairy;

-- Drop existing dairy schema tables if they exist
DROP SCHEMA IF EXISTS dairy CASCADE;

-- Create all tables in dairy schema
CREATE SCHEMA dairy;

-- Farmer table
CREATE TABLE dairy.farmer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    pan_number VARCHAR(20),
    aadhar_number VARCHAR(20),
    account_number VARCHAR(50),
    kyc_status VARCHAR(20) DEFAULT 'Pending',
    kyc_verified_at TIMESTAMP,
    bank_verified BOOLEAN DEFAULT FALSE,
    bank_verified_at TIMESTAMP,
    digilocker_verified BOOLEAN DEFAULT FALSE,
    aadhar_verified BOOLEAN DEFAULT FALSE,
    pan_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Milk collection table
CREATE TABLE dairy.milk_collection (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    collection_date DATE NOT NULL,
    quantity_liters DECIMAL(10,2) NOT NULL,
    fat_percentage DECIMAL(5,2),
    snf_percentage DECIMAL(5,2),
    rate_per_liter DECIMAL(10,2),
    total_amount DECIMAL(12,2),
    payment_status VARCHAR(20) DEFAULT 'Pending',
    payment_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Customer table
CREATE TABLE dairy.customer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Sales table
CREATE TABLE dairy.sale (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES dairy.customer(id),
    sale_date DATE NOT NULL,
    quantity_liters DECIMAL(10,2) NOT NULL,
    rate_per_liter DECIMAL(10,2),
    total_amount DECIMAL(12,2),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Payment tables
CREATE TABLE dairy.payment_customer (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES dairy.customer(id),
    amount DECIMAL(12,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(50),
    reference_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE dairy.payment_farmer (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    amount DECIMAL(12,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(50),
    reference_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- DigiLocker verification log
CREATE TABLE dairy.digilocker_verification_log (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    document_type VARCHAR(20) NOT NULL,
    document_number VARCHAR(50) NOT NULL,
    verification_status BOOLEAN NOT NULL,
    verified_name VARCHAR(255),
    verification_date TIMESTAMP DEFAULT NOW(),
    api_response JSONB
);

-- Tanker intake table
CREATE TABLE dairy.tanker_intake (
    id SERIAL PRIMARY KEY,
    batch_number VARCHAR(50) NOT NULL,
    supplier_name VARCHAR(255) NOT NULL,
    quantity_liters DECIMAL(10,2) NOT NULL,
    fat_percentage DECIMAL(5,2),
    snf_percentage DECIMAL(5,2),
    status VARCHAR(20) DEFAULT 'Received',
    received_at TIMESTAMP DEFAULT NOW(),
    processed_at TIMESTAMP
);

-- Insert sample data
INSERT INTO dairy.farmer (name, phone, pan_number, aadhar_number, account_number) VALUES
('Ramesh Kumar', '9876543210', 'ABCDE1234F', '123456789012', '1234567890'),
('Suresh Patil', '9876543211', 'FGHIJ5678K', '234567890123', '2345678901'),
('Mahesh Singh', '9876543212', 'KLMNO9012P', '345678901234', '3456789012');

INSERT INTO dairy.customer (name, phone, address) VALUES
('ABC Dairy Store', '9876543220', 'Market Road'),
('XYZ Milk Center', '9876543221', 'Station Road');

INSERT INTO dairy.milk_collection (farmer_id, collection_date, quantity_liters, fat_percentage, snf_percentage, rate_per_liter, total_amount) VALUES
(1, CURRENT_DATE, 25.5, 4.2, 8.5, 35.00, 892.50),
(2, CURRENT_DATE, 18.0, 3.8, 8.2, 32.00, 576.00),
(3, CURRENT_DATE, 30.2, 4.5, 8.8, 38.00, 1147.60);