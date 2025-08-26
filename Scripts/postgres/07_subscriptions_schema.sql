-- Subscription Management Schema
SET search_path TO dairy;

-- Products table (if not exists)
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_customer ON subscriptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_next_delivery ON subscriptions(next_delivery_date, status);
CREATE INDEX IF NOT EXISTS idx_subscription_deliveries_date ON subscription_deliveries(delivery_date);

-- Sample Data
INSERT INTO products (name, unit, price) VALUES
('Fresh Milk', 'Liters', 55.00),
('Toned Milk', 'Liters', 50.00),
('Full Cream Milk', 'Liters', 60.00),
('Paneer', 'Kg', 350.00),
('Curd', 'Liters', 45.00)
ON CONFLICT DO NOTHING;

-- Sample subscriptions
INSERT INTO subscriptions (customer_id, product_id, quantity, frequency, start_date, next_delivery_date) VALUES
(1, 1, 2.0, 'Daily', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day'),
(2, 2, 1.0, 'Daily', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day'),
(1, 4, 0.5, 'Weekly', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days')
ON CONFLICT DO NOTHING;