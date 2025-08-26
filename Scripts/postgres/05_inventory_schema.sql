-- Inventory Management Schema
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_item_date ON inventory_transactions(item_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_type ON inventory_transactions(transaction_type);

-- Sample Data
INSERT INTO inventory_items (name, unit, min_stock) VALUES
('Milk', 'Liters', 100.0),
('Paneer', 'Kg', 10.0),
('Ghee', 'Kg', 5.0),
('Butter', 'Kg', 8.0),
('Curd', 'Liters', 50.0)
ON CONFLICT DO NOTHING;

-- Sample transactions
INSERT INTO inventory_transactions (item_id, transaction_type, quantity, reference) VALUES
(1, 'IN', 500.0, 'Initial Stock'),
(2, 'IN', 25.0, 'Production'),
(3, 'IN', 15.0, 'Production'),
(1, 'OUT', 150.0, 'Sale Order #001'),
(2, 'OUT', 5.0, 'Sale Order #002')
ON CONFLICT DO NOTHING;