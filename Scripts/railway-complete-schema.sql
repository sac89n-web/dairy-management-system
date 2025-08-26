-- Railway PostgreSQL Complete Schema Setup
-- Run this script in Railway's PostgreSQL Query tool

-- Create dairy schema
CREATE SCHEMA IF NOT EXISTS dairy;
SET search_path TO dairy, public;

-- Users table
CREATE TABLE dairy.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'user',
    phone VARCHAR(15),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Farmers table
CREATE TABLE dairy.farmers (
    id SERIAL PRIMARY KEY,
    farmer_code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    bank_account VARCHAR(20),
    ifsc_code VARCHAR(11),
    rate_per_liter DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customers table
CREATE TABLE dairy.customers (
    id SERIAL PRIMARY KEY,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    rate_per_liter DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Milk collections table
CREATE TABLE dairy.milk_collections (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES dairy.farmers(id),
    quantity DECIMAL(10,2) NOT NULL,
    fat_percentage DECIMAL(5,2),
    snf_percentage DECIMAL(5,2),
    rate_per_liter DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    collection_date DATE DEFAULT CURRENT_DATE,
    collection_time TIME DEFAULT CURRENT_TIME,
    session VARCHAR(10) DEFAULT 'morning',
    payment_status VARCHAR(20) DEFAULT 'pending',
    created_by INTEGER REFERENCES dairy.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sales table
CREATE TABLE dairy.sales (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES dairy.customers(id),
    quantity DECIMAL(10,2) NOT NULL,
    rate_per_liter DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    sale_date DATE DEFAULT CURRENT_DATE,
    sale_time TIME DEFAULT CURRENT_TIME,
    payment_status VARCHAR(20) DEFAULT 'pending',
    created_by INTEGER REFERENCES dairy.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment transactions table
CREATE TABLE dairy.payment_transactions (
    id SERIAL PRIMARY KEY,
    transaction_type VARCHAR(20) NOT NULL, -- 'farmer_payment' or 'customer_payment'
    reference_id INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'cash',
    transaction_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_by INTEGER REFERENCES dairy.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Settings table
CREATE TABLE dairy.settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(50) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    updated_by INTEGER REFERENCES dairy.users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit log table
CREATE TABLE dairy.audit_logs (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(20) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    old_values JSONB,
    new_values JSONB,
    user_id INTEGER REFERENCES dairy.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin user (password: admin123)
INSERT INTO dairy.users (username, password_hash, full_name, role) 
VALUES ('admin', '$2a$11$8K1p/a0dURXAm/3f62tE7uxzanO.nnOhX0ttHBHp1WiUQOAEMAzAm', 'System Administrator', 'admin')
ON CONFLICT (username) DO NOTHING;

-- Insert default settings
INSERT INTO dairy.settings (setting_key, setting_value, description) VALUES
('default_fat_rate', '50.0', 'Default rate per unit fat percentage'),
('default_snf_rate', '90.0', 'Default rate per unit SNF percentage'),
('milk_price_per_liter', '45.0', 'Default milk selling price per liter'),
('company_name', 'Dairy Management System', 'Company name for reports'),
('currency', 'INR', 'Currency symbol')
ON CONFLICT (setting_key) DO NOTHING;

-- Sample farmers
INSERT INTO dairy.farmers (farmer_code, name, phone, rate_per_liter) VALUES
('F001', 'Ramesh Kumar', '9876543210', 42.0),
('F002', 'Suresh Patil', '9876543211', 41.5),
('F003', 'Mahesh Singh', '9876543212', 43.0)
ON CONFLICT (farmer_code) DO NOTHING;

-- Sample customers
INSERT INTO dairy.customers (customer_code, name, phone, rate_per_liter) VALUES
('C001', 'Local Store', '9876543220', 48.0),
('C002', 'Milk Distributor', '9876543221', 47.5),
('C003', 'Retail Shop', '9876543222', 49.0)
ON CONFLICT (customer_code) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_milk_collections_farmer_date ON dairy.milk_collections(farmer_id, collection_date);
CREATE INDEX IF NOT EXISTS idx_sales_customer_date ON dairy.sales(customer_id, sale_date);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_type_ref ON dairy.payment_transactions(transaction_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_record ON dairy.audit_logs(table_name, record_id);

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA dairy TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dairy TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dairy TO PUBLIC;

-- Success message
SELECT 'Database schema created successfully!' as status;