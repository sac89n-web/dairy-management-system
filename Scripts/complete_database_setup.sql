-- Complete Database Setup Script for Enhanced Dairy Management System
-- Run this script to set up all tables and sample data

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS dairy;

-- Add payment status columns to milk_collection table
ALTER TABLE dairy.milk_collection 
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'Pending',
ADD COLUMN IF NOT EXISTS payment_date TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS payment_reference VARCHAR(50) NULL;

-- Add SNF column to milk_collection table
ALTER TABLE dairy.milk_collection 
ADD COLUMN IF NOT EXISTS snf_pct DECIMAL(5,2) DEFAULT 8.5;

-- Update existing records
UPDATE dairy.milk_collection 
SET payment_status = 'Pending' 
WHERE payment_status IS NULL;

UPDATE dairy.milk_collection 
SET snf_pct = 8.5 + (fat_pct * 0.25) 
WHERE snf_pct IS NULL;

-- Create payment_transactions table
CREATE TABLE IF NOT EXISTS dairy.payment_transactions (
    id SERIAL PRIMARY KEY,
    payment_type VARCHAR(20) NOT NULL,
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    customer_id INTEGER REFERENCES dairy.customer(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending',
    reference_id VARCHAR(50) UNIQUE NOT NULL,
    transaction_id VARCHAR(100),
    gateway_response TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create quality_tests table
CREATE TABLE IF NOT EXISTS dairy.quality_tests (
    id SERIAL PRIMARY KEY,
    batch_id INTEGER NOT NULL,
    test_date DATE NOT NULL DEFAULT CURRENT_DATE,
    fat_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
    snf_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
    bacterial_count INTEGER DEFAULT 0,
    adulteration_detected BOOLEAN DEFAULT false,
    fssai_compliant BOOLEAN DEFAULT true,
    tested_by VARCHAR(100),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add missing columns to products table if they don't exist
ALTER TABLE dairy.products ADD COLUMN IF NOT EXISTS unit VARCHAR(20) DEFAULT 'Liter';
ALTER TABLE dairy.products ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'Milk';
ALTER TABLE dairy.products ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE dairy.products ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

-- Create invoices table if not exists
CREATE TABLE IF NOT EXISTS dairy.invoices (
    id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INTEGER REFERENCES dairy.customer(id),
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'Cash',
    status VARCHAR(20) DEFAULT 'Pending',
    paid_date DATE NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create routes table if not exists
CREATE TABLE IF NOT EXISTS dairy.routes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    driver_name VARCHAR(100),
    vehicle_number VARCHAR(20),
    status VARCHAR(20) DEFAULT 'Active',
    total_distance DECIMAL(8,2) DEFAULT 0,
    started_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create route_farmers table if not exists
CREATE TABLE IF NOT EXISTS dairy.route_farmers (
    id SERIAL PRIMARY KEY,
    route_id INTEGER REFERENCES dairy.routes(id),
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    sequence_order INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create subscriptions table if not exists
CREATE TABLE IF NOT EXISTS dairy.subscriptions (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES dairy.customer(id),
    product_id INTEGER REFERENCES dairy.products(id),
    quantity DECIMAL(8,2) NOT NULL,
    frequency VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    next_delivery_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create farmer_loans table if not exists
CREATE TABLE IF NOT EXISTS dairy.farmer_loans (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    loan_type VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    outstanding_amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    interest_rate DECIMAL(5,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create expenses table if not exists
CREATE TABLE IF NOT EXISTS dairy.expenses (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    branch_id INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_milk_collection_payment_status ON dairy.milk_collection(payment_status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_farmer_id ON dairy.payment_transactions(farmer_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON dairy.payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_quality_tests_batch_id ON dairy.quality_tests(batch_id);
CREATE INDEX IF NOT EXISTS idx_quality_tests_fssai_compliant ON dairy.quality_tests(fssai_compliant);

-- Insert sample products (using only name and price if other columns don't exist)
INSERT INTO dairy.products (name, price) VALUES
('Full Cream Milk', 55.00),
('Toned Milk', 50.00),
('Skimmed Milk', 45.00),
('Paneer', 350.00),
('Butter', 450.00),
('Ghee', 550.00),
('Curd', 60.00),
('Buttermilk', 25.00)
ON CONFLICT (name) DO NOTHING;

-- Insert sample quality tests
INSERT INTO dairy.quality_tests (batch_id, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by) VALUES
(1, 4.2, 8.5, 50000, false, true, 'Lab Technician A'),
(2, 3.8, 8.2, 45000, false, true, 'Lab Technician B'),
(3, 4.5, 8.8, 30000, false, true, 'Lab Technician A'),
(4, 3.5, 8.0, 180000, false, true, 'Lab Technician C'),
(5, 4.0, 8.3, 40000, false, true, 'Lab Technician B'),
(6, 4.1, 8.4, 35000, false, true, 'Lab Technician A'),
(7, 3.9, 8.1, 55000, false, true, 'Lab Technician B'),
(8, 4.3, 8.6, 25000, false, true, 'Lab Technician C'),
(9, 4.0, 8.2, 48000, false, true, 'Lab Technician A'),
(10, 4.2, 8.5, 42000, false, true, 'Lab Technician B')
ON CONFLICT DO NOTHING;

-- Insert sample payment transactions
INSERT INTO dairy.payment_transactions (payment_type, farmer_id, customer_id, amount, payment_method, status, reference_id) VALUES
('farmer', 1, NULL, 2758.00, 'UPI', 'Success', 'UPI' || EXTRACT(EPOCH FROM NOW())::bigint),
('farmer', 2, NULL, 1422.50, 'Cash', 'Success', 'CASH' || EXTRACT(EPOCH FROM NOW())::bigint),
('farmer', 3, NULL, 3758.00, 'UPI', 'Success', 'UPI' || (EXTRACT(EPOCH FROM NOW())::bigint + 1)),
('customer', NULL, 1, 2750.00, 'Card', 'Success', 'CARD' || EXTRACT(EPOCH FROM NOW())::bigint),
('customer', NULL, 2, 1770.00, 'Cash', 'Success', 'CASH' || (EXTRACT(EPOCH FROM NOW())::bigint + 2)),
('farmer', 4, NULL, 1845.00, 'UPI', 'Pending', 'UPI' || (EXTRACT(EPOCH FROM NOW())::bigint + 3)),
('farmer', 5, NULL, 2366.00, 'Cash', 'Success', 'CASH' || (EXTRACT(EPOCH FROM NOW())::bigint + 4))
ON CONFLICT (reference_id) DO NOTHING;

-- Insert sample routes
INSERT INTO dairy.routes (name, driver_name, vehicle_number, status, total_distance) VALUES
('Route A - East Zone', 'राहुल पवार', 'MH12AB1234', 'Active', 25.5),
('Route B - West Zone', 'अमित जोशी', 'MH12CD5678', 'Active', 18.2),
('Route C - North Zone', 'विकास शर्मा', 'MH12EF9012', 'In Progress', 22.8)
ON CONFLICT DO NOTHING;

-- Insert sample expenses
INSERT INTO dairy.expenses (category, amount, description, expense_date, branch_id) VALUES
('Transport', 2500.00, 'Fuel for collection vehicles', CURRENT_DATE, 1),
('Maintenance', 1800.00, 'Equipment servicing', CURRENT_DATE, 1),
('Utilities', 3200.00, 'Electricity and water bills', CURRENT_DATE, 1),
('Staff Salary', 45000.00, 'Monthly staff payments', CURRENT_DATE, 1),
('Feed Purchase', 15000.00, 'Cattle feed procurement', CURRENT_DATE - INTERVAL '1 day', 1),
('Veterinary', 2800.00, 'Animal health checkups', CURRENT_DATE - INTERVAL '2 days', 1)
ON CONFLICT DO NOTHING;

-- Update some milk collections to show paid status
UPDATE dairy.milk_collection 
SET payment_status = 'Paid', payment_date = CURRENT_DATE - INTERVAL '1 day'
WHERE id IN (SELECT id FROM dairy.milk_collection ORDER BY RANDOM() LIMIT 3);

-- Update some collections with payment references
UPDATE dairy.milk_collection 
SET payment_reference = 'PAY' || id || EXTRACT(EPOCH FROM NOW())::bigint
WHERE payment_status = 'Paid';

-- Insert sample invoices
INSERT INTO dairy.invoices (invoice_number, customer_id, invoice_date, subtotal, tax_amount, total_amount, payment_method, status) VALUES
('INV' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '001', 1, CURRENT_DATE, 2750.00, 495.00, 3245.00, 'Credit', 'Pending'),
('INV' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '002', 2, CURRENT_DATE, 1500.00, 270.00, 1770.00, 'Cash', 'Paid'),
('INV' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '003', 3, CURRENT_DATE, 4500.00, 810.00, 5310.00, 'UPI', 'Paid')
ON CONFLICT (invoice_number) DO NOTHING;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '=== DATABASE SETUP COMPLETE ===';
    RAISE NOTICE 'Enhanced features added:';
    RAISE NOTICE '✓ Payment status tracking';
    RAISE NOTICE '✓ Quality control system';
    RAISE NOTICE '✓ Payment transactions';
    RAISE NOTICE '✓ Sample data for demo';
    RAISE NOTICE '✓ All indexes created';
    RAISE NOTICE 'Dashboard and Payment Gateway enhanced features are now ready!';
END $$;