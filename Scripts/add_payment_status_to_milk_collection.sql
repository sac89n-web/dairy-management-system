-- Add payment status to milk_collection table
ALTER TABLE dairy.milk_collection 
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'Pending',
ADD COLUMN IF NOT EXISTS payment_date TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS payment_reference VARCHAR(50) NULL;

-- Update existing records
UPDATE dairy.milk_collection 
SET payment_status = 'Pending' 
WHERE payment_status IS NULL;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_milk_collection_payment_status ON dairy.milk_collection(payment_status);