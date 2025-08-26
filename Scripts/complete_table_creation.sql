-- Complete Table Creation Script for Dairy Management System
-- Run this script in PostgreSQL to create all required tables

CREATE SCHEMA IF NOT EXISTS dairy;
SET search_path TO dairy;

-- Inventory Management Tables
CREATE TABLE IF NOT EXISTS inventory_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'Liters',
    min_stock DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inventory_transactions (
    id SERIAL PRIMARY KEY,
    item_id INT NOT NULL REFERENCES inventory_items(id),
    transaction_type VARCHAR(10) NOT NULL CHECK (transaction_type IN ('IN', 'OUT')),
    quantity DECIMAL(10,2) NOT NULL CHECK (quantity > 0),
    reference VARCHAR(255),
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Route Management Tables
CREATE TABLE IF NOT EXISTS routes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    driver_name VARCHAR(100) NOT NULL,
    vehicle_number VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'In Progress', 'Completed', 'Inactive')),
    total_distance DECIMAL(8,2) DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS route_farmers (
    id SERIAL PRIMARY KEY,
    route_id INT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    farmer_id INT NOT NULL REFERENCES farmer(id) ON DELETE CASCADE,
    sequence_order INT NOT NULL,
    estimated_time TIME,
    UNIQUE(route_id, farmer_id)
);

-- Product Management Tables
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) DEFAULT 'Liters',
    price DECIMAL(8,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscription Management Tables
CREATE TABLE IF NOT EXISTS subscriptions (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customer(id),
    product_id INT NOT NULL REFERENCES products(id),
    quantity DECIMAL(8,2) NOT NULL CHECK (quantity > 0),
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('Daily', 'Weekly', 'Monthly')),
    start_date DATE NOT NULL,
    next_delivery_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Paused', 'Cancelled', 'Completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscription_deliveries (
    id SERIAL PRIMARY KEY,
    subscription_id INT NOT NULL REFERENCES subscriptions(id),
    delivery_date DATE NOT NULL,
    delivered_quantity DECIMAL(8,2),
    status VARCHAR(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Delivered', 'Failed', 'Cancelled')),
    notes TEXT,
    delivered_by INT REFERENCES employee(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Farmer Loans & Advances Tables
CREATE TABLE IF NOT EXISTS farmer_loans (
    id SERIAL PRIMARY KEY,
    farmer_id INT NOT NULL REFERENCES farmer(id),
    loan_type VARCHAR(20) NOT NULL CHECK (loan_type IN ('Advance', 'Loan')),
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    outstanding_amount DECIMAL(12,2) NOT NULL CHECK (outstanding_amount >= 0),
    due_date DATE NOT NULL,
    interest_rate DECIMAL(5,2) DEFAULT 0 CHECK (interest_rate >= 0 AND interest_rate <= 36),
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Paid', 'Overdue', 'Cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS loan_payments (
    id SERIAL PRIMARY KEY,
    loan_id INT NOT NULL REFERENCES farmer_loans(id),
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Invoice Management Tables
CREATE TABLE IF NOT EXISTS invoices (
    id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(30) UNIQUE NOT NULL,
    customer_id INT REFERENCES customer(id),
    invoice_date DATE NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    tax_amount DECIMAL(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('Cash', 'UPI', 'Card', 'Credit')),
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Paid', 'Cancelled', 'Overdue')),
    paid_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(id),
    quantity DECIMAL(8,2) NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(8,2) NOT NULL CHECK (unit_price >= 0),
    total_price DECIMAL(12,2) NOT NULL CHECK (total_price >= 0)
);

-- Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_item_date ON inventory_transactions(item_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_type ON inventory_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_route_farmers_route ON route_farmers(route_id);
CREATE INDEX IF NOT EXISTS idx_route_farmers_farmer ON route_farmers(farmer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_customer ON subscriptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_next_delivery ON subscriptions(next_delivery_date, status);
CREATE INDEX IF NOT EXISTS idx_subscription_deliveries_date ON subscription_deliveries(delivery_date);
CREATE INDEX IF NOT EXISTS idx_farmer_loans_farmer ON farmer_loans(farmer_id);
CREATE INDEX IF NOT EXISTS idx_farmer_loans_status ON farmer_loans(status);
CREATE INDEX IF NOT EXISTS idx_farmer_loans_due_date ON farmer_loans(due_date);
CREATE INDEX IF NOT EXISTS idx_loan_payments_loan ON loan_payments(loan_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(invoice_date);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_items_product ON invoice_items(product_id);

-- Insert Sample Data
INSERT INTO inventory_items (name, unit, min_stock) VALUES
('Milk', 'Liters', 100.0),
('Paneer', 'Kg', 10.0),
('Ghee', 'Kg', 5.0),
('Butter', 'Kg', 8.0),
('Curd', 'Liters', 50.0)
ON CONFLICT DO NOTHING;

INSERT INTO inventory_transactions (item_id, transaction_type, quantity, reference) VALUES
(1, 'IN', 500.0, 'Initial Stock'),
(2, 'IN', 25.0, 'Production'),
(3, 'IN', 15.0, 'Production'),
(1, 'OUT', 150.0, 'Sale Order #001'),
(2, 'OUT', 5.0, 'Sale Order #002')
ON CONFLICT DO NOTHING;

INSERT INTO products (name, unit, price) VALUES
('Fresh Milk', 'Liters', 55.00),
('Toned Milk', 'Liters', 50.00),
('Full Cream Milk', 'Liters', 60.00),
('Paneer', 'Kg', 350.00),
('Curd', 'Liters', 45.00),
('Butter', 'Kg', 450.00),
('Ghee', 'Kg', 550.00)
ON CONFLICT DO NOTHING;

INSERT INTO routes (name, driver_name, vehicle_number, total_distance) VALUES
('Route A - North', 'Ramesh Kumar', 'MH12AB1234', 25.5),
('Route B - South', 'Suresh Patil', 'MH12CD5678', 18.2),
('Route C - East', 'Mahesh Singh', 'MH12EF9012', 32.1)
ON CONFLICT DO NOTHING;

-- Assign farmers to routes (if farmers exist)
INSERT INTO route_farmers (route_id, farmer_id, sequence_order) 
SELECT 1, f.id, 1 FROM farmer f WHERE f.code = 'F001' LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO route_farmers (route_id, farmer_id, sequence_order) 
SELECT 1, f.id, 2 FROM farmer f WHERE f.code = 'F002' LIMIT 1
ON CONFLICT DO NOTHING;

-- Sample subscriptions (if customers exist)
INSERT INTO subscriptions (customer_id, product_id, quantity, frequency, start_date, next_delivery_date) 
SELECT c.id, 1, 2.0, 'Daily', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day'
FROM customer c LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO subscriptions (customer_id, product_id, quantity, frequency, start_date, next_delivery_date) 
SELECT c.id, 2, 1.0, 'Daily', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day'
FROM customer c LIMIT 1
ON CONFLICT DO NOTHING;

-- Sample farmer loans
INSERT INTO farmer_loans (farmer_id, loan_type, amount, outstanding_amount, due_date, interest_rate) 
SELECT f.id, 'Advance', 5000.00, 5000.00, CURRENT_DATE + INTERVAL '30 days', 0.0
FROM farmer f WHERE f.code = 'F001' LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO farmer_loans (farmer_id, loan_type, amount, outstanding_amount, due_date, interest_rate) 
SELECT f.id, 'Loan', 15000.00, 15000.00, CURRENT_DATE + INTERVAL '90 days', 12.0
FROM farmer f WHERE f.code = 'F002' LIMIT 1
ON CONFLICT DO NOTHING;

COMMIT;

-- Display success message
SELECT 'All tables created successfully with sample data!' as status;