-- Complete Dairy Management System Database Schema
-- PostgreSQL with 'dairy' schema

-- Create schema
CREATE SCHEMA IF NOT EXISTS dairy;
SET search_path TO dairy;

-- Drop existing tables if they exist (in correct order)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS payment_customers CASCADE;
DROP TABLE IF EXISTS payment_farmers CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS milk_collections CASCADE;
DROP TABLE IF EXISTS rate_slabs CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS farmers CASCADE;
DROP TABLE IF EXISTS shifts CASCADE;
DROP TABLE IF EXISTS branches CASCADE;
DROP TABLE IF EXISTS banks CASCADE;

-- 1. Banks table
CREATE TABLE banks (
    id SERIAL PRIMARY KEY,
    bank_name VARCHAR(100) NOT NULL,
    branch_name VARCHAR(100),
    ifsc_code VARCHAR(11),
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Branches table
CREATE TABLE branches (
    id SERIAL PRIMARY KEY,
    branch_code VARCHAR(10) UNIQUE NOT NULL,
    branch_name VARCHAR(100) NOT NULL,
    address TEXT,
    phone VARCHAR(15),
    manager_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Shifts table
CREATE TABLE shifts (
    id SERIAL PRIMARY KEY,
    shift_name VARCHAR(50) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Farmers table
CREATE TABLE farmers (
    id SERIAL PRIMARY KEY,
    farmer_code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    mobile VARCHAR(15),
    address TEXT,
    bank_id INTEGER REFERENCES banks(id),
    account_number VARCHAR(20),
    branch_id INTEGER REFERENCES branches(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Customers table
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    mobile VARCHAR(15),
    address TEXT,
    customer_type VARCHAR(20) DEFAULT 'Regular',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'Operator',
    full_name VARCHAR(100),
    email VARCHAR(100),
    mobile VARCHAR(15),
    branch_id INTEGER REFERENCES branches(id),
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Settings table
CREATE TABLE settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    category VARCHAR(50) DEFAULT 'General',
    updated_by INTEGER REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Rate Slabs table
CREATE TABLE rate_slabs (
    id SERIAL PRIMARY KEY,
    fat_min DECIMAL(4,2) NOT NULL,
    fat_max DECIMAL(4,2) NOT NULL,
    snf_min DECIMAL(4,2) NOT NULL,
    snf_max DECIMAL(4,2) NOT NULL,
    base_rate DECIMAL(8,2) NOT NULL,
    fat_incentive DECIMAL(8,2) DEFAULT 0,
    snf_incentive DECIMAL(8,2) DEFAULT 0,
    quality_bonus DECIMAL(8,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    effective_from DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Milk Collections table
CREATE TABLE milk_collections (
    id SERIAL PRIMARY KEY,
    collection_date DATE NOT NULL,
    farmer_id INTEGER NOT NULL REFERENCES farmers(id),
    shift_id INTEGER NOT NULL REFERENCES shifts(id),
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    quantity DECIMAL(8,2) NOT NULL,
    fat DECIMAL(4,2) NOT NULL,
    snf DECIMAL(4,2) NOT NULL,
    rate DECIMAL(8,2) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'Pending',
    quality_grade VARCHAR(10) DEFAULT 'A',
    temperature DECIMAL(4,1),
    ph_level DECIMAL(3,1),
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Sales table
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    sale_date DATE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    quantity DECIMAL(8,2) NOT NULL,
    rate DECIMAL(8,2) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'Pending',
    payment_method VARCHAR(20) DEFAULT 'Cash',
    invoice_number VARCHAR(50),
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Payment Farmers table
CREATE TABLE payment_farmers (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER NOT NULL REFERENCES farmers(id),
    payment_date DATE NOT NULL,
    period_from DATE NOT NULL,
    period_to DATE NOT NULL,
    total_quantity DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    deductions DECIMAL(10,2) DEFAULT 0,
    net_amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'Bank Transfer',
    reference_number VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Pending',
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. Payment Customers table
CREATE TABLE payment_customers (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    payment_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'Cash',
    reference_number VARCHAR(100),
    description TEXT,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. Audit Logs table
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    user_id INTEGER REFERENCES users(id),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_milk_collections_date ON milk_collections(collection_date);
CREATE INDEX idx_milk_collections_farmer ON milk_collections(farmer_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_payment_farmers_date ON payment_farmers(payment_date);
CREATE INDEX idx_payment_customers_date ON payment_customers(payment_date);
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);

-- Insert default data
INSERT INTO banks (bank_name, branch_name, ifsc_code) VALUES
('State Bank of India', 'Main Branch', 'SBIN0000001'),
('HDFC Bank', 'Commercial Branch', 'HDFC0000001'),
('ICICI Bank', 'Business Branch', 'ICIC0000001');

INSERT INTO branches (branch_code, branch_name, address, manager_name) VALUES
('BR001', 'Main Collection Center', 'Village Center, Main Road', 'Rajesh Kumar'),
('BR002', 'North Collection Point', 'North Village, Highway Road', 'Suresh Patil');

INSERT INTO shifts (shift_name, start_time, end_time) VALUES
('Morning', '06:00:00', '10:00:00'),
('Evening', '17:00:00', '20:00:00');

-- Insert admin user (password: admin123)
INSERT INTO users (username, password_hash, role, full_name, is_active) VALUES
('admin', '$2a$11$rGZX8Z9X8Z9X8Z9X8Z9X8O', 'Admin', 'System Administrator', true);

-- Insert default settings
INSERT INTO settings (setting_key, setting_value, description, category) VALUES
('company_name', 'Dairy Management System', 'Company Name', 'General'),
('currency', 'INR', 'Default Currency', 'General'),
('decimal_places', '2', 'Decimal Places for Amounts', 'General'),
('default_fat_rate', '3.5', 'Default FAT percentage', 'Quality'),
('default_snf_rate', '8.5', 'Default SNF percentage', 'Quality'),
('min_fat_percentage', '2.0', 'Minimum FAT percentage', 'Quality'),
('max_fat_percentage', '8.0', 'Maximum FAT percentage', 'Quality'),
('min_snf_percentage', '7.0', 'Minimum SNF percentage', 'Quality'),
('max_snf_percentage', '12.0', 'Maximum SNF percentage', 'Quality');

-- Insert sample rate slabs
INSERT INTO rate_slabs (fat_min, fat_max, snf_min, snf_max, base_rate, fat_incentive, snf_incentive) VALUES
(3.0, 3.5, 8.0, 8.5, 25.00, 0.50, 0.30),
(3.5, 4.0, 8.5, 9.0, 27.00, 0.60, 0.35),
(4.0, 4.5, 9.0, 9.5, 29.00, 0.70, 0.40),
(4.5, 5.0, 9.5, 10.0, 31.00, 0.80, 0.45);

-- Insert sample farmers
INSERT INTO farmers (farmer_code, name, mobile, address, bank_id, account_number, branch_id) VALUES
('F001', 'Ramesh Sharma', '9876543210', 'Village Dairy Farm, Plot 123', 1, '1234567890', 1),
('F002', 'Suresh Patil', '9876543211', 'Milk Producer Society, Area 2', 2, '2345678901', 1),
('F003', 'Mahesh Kumar', '9876543212', 'Cooperative Farm, Sector 3', 1, '3456789012', 2);

-- Insert sample customers
INSERT INTO customers (customer_code, name, mobile, address, customer_type) VALUES
('C001', 'Local Dairy Shop', '9876543220', 'Main Market, Shop 15', 'Wholesale'),
('C002', 'Milk Distribution Center', '9876543221', 'Commercial Complex, Unit 5', 'Bulk'),
('C003', 'Retail Customer', '9876543222', 'Residential Area, House 25', 'Regular');

COMMIT;

-- Display summary
SELECT 'Database schema created successfully!' as status;
SELECT schemaname, tablename, tableowner 
FROM pg_tables 
WHERE schemaname = 'dairy' 
ORDER BY tablename;