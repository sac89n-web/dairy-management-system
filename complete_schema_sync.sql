-- Complete Database Schema Synchronization
-- This script ensures all required tables exist with proper structure
-- Run this on both LOCAL and RENDER databases

-- Create dairy schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS dairy;
SET search_path TO dairy;

-- 1. Branch table
CREATE TABLE IF NOT EXISTS branch (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    contact VARCHAR(15),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Employee table
CREATE TABLE IF NOT EXISTS employee (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(15),
    branch_id INTEGER REFERENCES branch(id),
    role VARCHAR(50) DEFAULT 'Employee',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Shift table
CREATE TABLE IF NOT EXISTS shift (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Farmer table
CREATE TABLE IF NOT EXISTS farmer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    contact VARCHAR(15),
    address TEXT,
    bank_account_number VARCHAR(20),
    bank_ifsc_code VARCHAR(11),
    branch_id INTEGER REFERENCES branch(id),
    kyc_status VARCHAR(20) DEFAULT 'pending',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Customer table
CREATE TABLE IF NOT EXISTS customer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(15),
    address TEXT,
    branch_id INTEGER REFERENCES branch(id),
    customer_type VARCHAR(20) DEFAULT 'Regular',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Users table (for authentication)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100),
    full_name VARCHAR(100) NOT NULL,
    mobile VARCHAR(15),
    password_hash VARCHAR(255) NOT NULL,
    role INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    branch_id INTEGER REFERENCES branch(id),
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Milk Collection table
CREATE TABLE IF NOT EXISTS milk_collection (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER NOT NULL REFERENCES farmer(id),
    shift_id INTEGER NOT NULL REFERENCES shift(id),
    date DATE NOT NULL,
    qty_ltr NUMERIC(8,2) NOT NULL,
    fat_pct NUMERIC(4,2) NOT NULL,
    snf_pct NUMERIC(4,2) NOT NULL,
    price_per_ltr NUMERIC(8,2) NOT NULL,
    due_amt NUMERIC(12,2) NOT NULL,
    slip_number VARCHAR(50),
    notes TEXT,
    created_by INTEGER REFERENCES employee(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(farmer_id, shift_id, date)
);

-- 8. Sale table
CREATE TABLE IF NOT EXISTS sale (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customer(id),
    shift_id INTEGER REFERENCES shift(id),
    date DATE NOT NULL,
    qty_ltr NUMERIC(8,2) NOT NULL,
    unit_price NUMERIC(8,2) NOT NULL,
    discount NUMERIC(8,2) DEFAULT 0,
    paid_amt NUMERIC(12,2) NOT NULL,
    due_amt NUMERIC(12,2) NOT NULL,
    invoice_number VARCHAR(50),
    created_by INTEGER REFERENCES employee(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Payment Farmer table
CREATE TABLE IF NOT EXISTS payment_farmer (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER NOT NULL REFERENCES farmer(id),
    milk_collection_id INTEGER REFERENCES milk_collection(id),
    amount NUMERIC(12,2) NOT NULL,
    date DATE NOT NULL,
    invoice_no VARCHAR(30) UNIQUE,
    pdf_path VARCHAR(255),
    payment_method VARCHAR(20) DEFAULT 'Bank Transfer',
    reference_number VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Payment Customer table
CREATE TABLE IF NOT EXISTS payment_customer (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customer(id),
    sale_id INTEGER REFERENCES sale(id),
    amount NUMERIC(12,2) NOT NULL,
    date DATE NOT NULL,
    invoice_no VARCHAR(30) UNIQUE,
    pdf_path VARCHAR(255),
    payment_method VARCHAR(20) DEFAULT 'Cash',
    reference_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Audit Log table
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    action VARCHAR(100) NOT NULL,
    entity VARCHAR(50),
    entity_id INTEGER,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

-- 12. Settings table
CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    category VARCHAR(50) DEFAULT 'General',
    updated_by INTEGER REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. Rate Slabs table (for pricing)
CREATE TABLE IF NOT EXISTS rate_slabs (
    id SERIAL PRIMARY KEY,
    fat_min NUMERIC(4,2) NOT NULL,
    fat_max NUMERIC(4,2) NOT NULL,
    snf_min NUMERIC(4,2) NOT NULL,
    snf_max NUMERIC(4,2) NOT NULL,
    base_rate NUMERIC(8,2) NOT NULL,
    fat_incentive NUMERIC(8,2) DEFAULT 0,
    snf_incentive NUMERIC(8,2) DEFAULT 0,
    quality_bonus NUMERIC(8,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    effective_from DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 14. Payment Cycles table (for batch payments)
CREATE TABLE IF NOT EXISTS payment_cycles (
    id SERIAL PRIMARY KEY,
    cycle_name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'draft',
    total_farmers INTEGER DEFAULT 0,
    total_amount NUMERIC(15,2) DEFAULT 0,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- 15. Payment Cycle Details table
CREATE TABLE IF NOT EXISTS payment_cycle_details (
    id SERIAL PRIMARY KEY,
    cycle_id INTEGER NOT NULL REFERENCES payment_cycles(id),
    farmer_id INTEGER NOT NULL REFERENCES farmer(id),
    total_quantity NUMERIC(10,2) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    deductions NUMERIC(10,2) DEFAULT 0,
    bonus_amount NUMERIC(10,2) DEFAULT 0,
    final_amount NUMERIC(12,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 16. Bonus Configurations table
CREATE TABLE IF NOT EXISTS bonus_configurations (
    id SERIAL PRIMARY KEY,
    config_name VARCHAR(100) NOT NULL,
    bonus_type VARCHAR(50) NOT NULL,
    calculation_method VARCHAR(50) NOT NULL,
    criteria JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_to DATE,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 17. System Alerts table
CREATE TABLE IF NOT EXISTS system_alerts (
    id SERIAL PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    entity_type VARCHAR(50),
    entity_id INTEGER,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_by INTEGER REFERENCES users(id),
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 18. Hardware Devices table
CREATE TABLE IF NOT EXISTS hardware_devices (
    id SERIAL PRIMARY KEY,
    device_name VARCHAR(100) NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    serial_number VARCHAR(100) UNIQUE,
    branch_id INTEGER REFERENCES branch(id),
    status VARCHAR(20) DEFAULT 'active',
    last_sync TIMESTAMP,
    configuration JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_milk_collection_date ON milk_collection(date);
CREATE INDEX IF NOT EXISTS idx_milk_collection_farmer ON milk_collection(farmer_id);
CREATE INDEX IF NOT EXISTS idx_milk_collection_farmer_date ON milk_collection(farmer_id, date);
CREATE INDEX IF NOT EXISTS idx_sale_date ON sale(date);
CREATE INDEX IF NOT EXISTS idx_sale_customer ON sale(customer_id);
CREATE INDEX IF NOT EXISTS idx_payment_farmer_date ON payment_farmer(date);
CREATE INDEX IF NOT EXISTS idx_payment_customer_date ON payment_customer(date);
CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON audit_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_farmer_code ON farmer(code);
CREATE INDEX IF NOT EXISTS idx_payment_cycles_dates ON payment_cycles(start_date, end_date);

-- Insert default data (only if tables are empty)
INSERT INTO branch (name, address, contact) 
SELECT 'Main Branch', '123 Dairy Lane', '9876543210'
WHERE NOT EXISTS (SELECT 1 FROM branch);

INSERT INTO employee (name, contact, branch_id, role) 
SELECT 'Admin User', '9999999999', 1, 'Admin'
WHERE NOT EXISTS (SELECT 1 FROM employee);

INSERT INTO shift (name, start_time, end_time) 
SELECT * FROM (VALUES 
    ('Morning', '06:00:00', '10:00:00'),
    ('Evening', '18:00:00', '21:00:00')
) AS v(name, start_time, end_time)
WHERE NOT EXISTS (SELECT 1 FROM shift WHERE shift.name = v.name);

INSERT INTO users (username, email, full_name, password_hash, role, is_active) 
SELECT 'admin', 'admin@dairy.com', 'System Administrator', 'admin123', 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

INSERT INTO farmer (name, code, contact, branch_id) 
SELECT 'Test Farmer', 'F001', '7777777777', 1
WHERE NOT EXISTS (SELECT 1 FROM farmer WHERE code = 'F001');

INSERT INTO customer (name, contact, branch_id) 
SELECT 'Test Customer', '5555555555', 1
WHERE NOT EXISTS (SELECT 1 FROM customer);

-- Insert default settings
INSERT INTO settings (setting_key, setting_value, description, category)
SELECT * FROM (VALUES
    ('company_name', 'Dairy Management System', 'Company Name', 'General'),
    ('currency', 'INR', 'Default Currency', 'General'),
    ('decimal_places', '2', 'Decimal Places for Amounts', 'General'),
    ('default_fat_rate', '3.5', 'Default FAT percentage', 'Quality'),
    ('default_snf_rate', '8.5', 'Default SNF percentage', 'Quality'),
    ('min_fat_percentage', '2.0', 'Minimum FAT percentage', 'Quality'),
    ('max_fat_percentage', '8.0', 'Maximum FAT percentage', 'Quality'),
    ('min_snf_percentage', '7.0', 'Minimum SNF percentage', 'Quality'),
    ('max_snf_percentage', '12.0', 'Maximum SNF percentage', 'Quality')
) AS v(setting_key, setting_value, description, category)
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE settings.setting_key = v.setting_key);

-- Insert sample rate slabs
INSERT INTO rate_slabs (fat_min, fat_max, snf_min, snf_max, base_rate, fat_incentive, snf_incentive)
SELECT * FROM (VALUES
    (3.0, 3.5, 8.0, 8.5, 25.00, 0.50, 0.30),
    (3.5, 4.0, 8.5, 9.0, 27.00, 0.60, 0.35),
    (4.0, 4.5, 9.0, 9.5, 29.00, 0.70, 0.40),
    (4.5, 5.0, 9.5, 10.0, 31.00, 0.80, 0.45)
) AS v(fat_min, fat_max, snf_min, snf_max, base_rate, fat_incentive, snf_incentive)
WHERE NOT EXISTS (SELECT 1 FROM rate_slabs);

-- Verify schema creation
SELECT 
    'Schema synchronization completed!' as status,
    COUNT(*) as total_tables
FROM information_schema.tables 
WHERE table_schema = 'dairy';

-- List all created tables
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'dairy' AND table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'dairy'
ORDER BY table_name;