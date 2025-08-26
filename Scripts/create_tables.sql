-- Create all missing tables for Dairy Management System
CREATE SCHEMA IF NOT EXISTS dairy;
SET search_path TO dairy;

-- Inventory Items
CREATE TABLE IF NOT EXISTS inventory_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'Liters',
    min_stock DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inventory Transactions
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id SERIAL PRIMARY KEY,
    item_id INT NOT NULL REFERENCES inventory_items(id),
    transaction_type VARCHAR(10) NOT NULL CHECK (transaction_type IN ('IN', 'OUT')),
    quantity DECIMAL(10,2) NOT NULL CHECK (quantity > 0),
    reference VARCHAR(255),
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Routes
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

-- Route Farmers
CREATE TABLE IF NOT EXISTS route_farmers (
    id SERIAL PRIMARY KEY,
    route_id INT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    farmer_id INT NOT NULL REFERENCES farmer(id) ON DELETE CASCADE,
    sequence_order INT NOT NULL,
    estimated_time TIME,
    UNIQUE(route_id, farmer_id)
);

-- Products
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) DEFAULT 'Liters',
    price DECIMAL(8,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscriptions
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

-- Subscription Deliveries
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_item_date ON inventory_transactions(item_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_route_farmers_route ON route_farmers(route_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_customer ON subscriptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_next_delivery ON subscriptions(next_delivery_date, status);

-- Insert sample data
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
(3, 'IN', 15.0, 'Production')
ON CONFLICT DO NOTHING;

INSERT INTO products (name, unit, price) VALUES
('Fresh Milk', 'Liters', 55.00),
('Toned Milk', 'Liters', 50.00),
('Full Cream Milk', 'Liters', 60.00),
('Paneer', 'Kg', 350.00),
('Curd', 'Liters', 45.00)
ON CONFLICT DO NOTHING;

INSERT INTO routes (name, driver_name, vehicle_number, total_distance) VALUES
('Route A - North', 'Ramesh Kumar', 'MH12AB1234', 25.5),
('Route B - South', 'Suresh Patil', 'MH12CD5678', 18.2),
('Route C - East', 'Mahesh Singh', 'MH12EF9012', 32.1)
ON CONFLICT DO NOTHING;

-- Assign farmers to routes (if farmers exist)
INSERT INTO route_farmers (route_id, farmer_id, sequence_order) 
SELECT 1, f.id, 1 FROM farmer f WHERE f.code = 'F001'
ON CONFLICT DO NOTHING;

INSERT INTO route_farmers (route_id, farmer_id, sequence_order) 
SELECT 1, f.id, 2 FROM farmer f WHERE f.code = 'F002'
ON CONFLICT DO NOTHING;

-- Sample subscriptions (if customers exist)
INSERT INTO subscriptions (customer_id, product_id, quantity, frequency, start_date, next_delivery_date) 
SELECT c.id, 1, 2.0, 'Daily', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day'
FROM customer c LIMIT 1
ON CONFLICT DO NOTHING;

COMMIT;