-- Create payment_transactions table for payment gateway functionality

CREATE TABLE IF NOT EXISTS dairy.payment_transactions (
    id SERIAL PRIMARY KEY,
    payment_type VARCHAR(20) NOT NULL, -- 'farmer' or 'customer'
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    customer_id INTEGER REFERENCES dairy.customer(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL, -- 'UPI', 'Card', 'NetBanking', 'Cash'
    status VARCHAR(20) DEFAULT 'Pending', -- 'Pending', 'Success', 'Failed'
    reference_id VARCHAR(50) UNIQUE NOT NULL,
    transaction_id VARCHAR(100), -- External payment gateway transaction ID
    gateway_response TEXT, -- JSON response from payment gateway
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_transactions_farmer_id ON dairy.payment_transactions(farmer_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_customer_id ON dairy.payment_transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON dairy.payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created_at ON dairy.payment_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_reference_id ON dairy.payment_transactions(reference_id);

-- Insert sample data
INSERT INTO dairy.payment_transactions (payment_type, farmer_id, amount, payment_method, status, reference_id) VALUES
('farmer', 1, 5000.00, 'UPI', 'Success', 'UPI' || EXTRACT(EPOCH FROM NOW())::bigint),
('farmer', 2, 3500.00, 'Cash', 'Success', 'CASH' || EXTRACT(EPOCH FROM NOW())::bigint),
('customer', 1, 2000.00, 'Card', 'Success', 'CARD' || EXTRACT(EPOCH FROM NOW())::bigint);