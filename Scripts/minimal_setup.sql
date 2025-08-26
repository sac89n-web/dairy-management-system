-- Minimal Database Setup - Only Essential Tables for Enhanced Features

-- Add payment status to milk_collection
ALTER TABLE dairy.milk_collection 
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'Pending',
ADD COLUMN IF NOT EXISTS payment_date TIMESTAMP NULL,
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
    farmer_id INTEGER,
    customer_id INTEGER,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending',
    reference_id VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
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
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample quality tests
INSERT INTO dairy.quality_tests (batch_id, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by) VALUES
(1, 4.2, 8.5, 50000, false, true, 'Lab Tech A'),
(2, 3.8, 8.2, 45000, false, true, 'Lab Tech B'),
(3, 4.5, 8.8, 30000, false, true, 'Lab Tech A'),
(4, 3.5, 8.0, 180000, false, true, 'Lab Tech C'),
(5, 4.0, 8.3, 40000, false, true, 'Lab Tech B')
ON CONFLICT DO NOTHING;

-- Insert sample payment transactions
INSERT INTO dairy.payment_transactions (payment_type, farmer_id, amount, payment_method, status, reference_id) VALUES
('farmer', 1, 2758.00, 'UPI', 'Success', 'UPI' || EXTRACT(EPOCH FROM NOW())::bigint),
('farmer', 2, 1422.50, 'Cash', 'Success', 'CASH' || EXTRACT(EPOCH FROM NOW())::bigint),
('farmer', 3, 3758.00, 'UPI', 'Success', 'UPI' || (EXTRACT(EPOCH FROM NOW())::bigint + 1))
ON CONFLICT (reference_id) DO NOTHING;

-- Update some collections to paid status
UPDATE dairy.milk_collection 
SET payment_status = 'Paid', payment_date = CURRENT_DATE - INTERVAL '1 day'
WHERE id IN (SELECT id FROM dairy.milk_collection ORDER BY RANDOM() LIMIT 2);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON dairy.payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_quality_tests_fssai ON dairy.quality_tests(fssai_compliant);

-- Success message
SELECT 'Enhanced features setup complete!' as status;