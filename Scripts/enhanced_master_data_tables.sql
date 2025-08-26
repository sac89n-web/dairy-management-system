-- Enhanced Farmer Table
ALTER TABLE dairy.farmer 
ADD COLUMN IF NOT EXISTS email VARCHAR(100),
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS village VARCHAR(100),
ADD COLUMN IF NOT EXISTS taluka VARCHAR(100),
ADD COLUMN IF NOT EXISTS district VARCHAR(100),
ADD COLUMN IF NOT EXISTS state VARCHAR(50) DEFAULT 'Maharashtra',
ADD COLUMN IF NOT EXISTS pincode VARCHAR(10),
ADD COLUMN IF NOT EXISTS bank_name VARCHAR(100),
ADD COLUMN IF NOT EXISTS account_number VARCHAR(20),
ADD COLUMN IF NOT EXISTS ifsc_code VARCHAR(15),
ADD COLUMN IF NOT EXISTS aadhar_number VARCHAR(12),
ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10),
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Enhanced Customer Table
ALTER TABLE dairy.customer 
ADD COLUMN IF NOT EXISTS email VARCHAR(100),
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city VARCHAR(100),
ADD COLUMN IF NOT EXISTS state VARCHAR(50) DEFAULT 'Maharashtra',
ADD COLUMN IF NOT EXISTS pincode VARCHAR(10),
ADD COLUMN IF NOT EXISTS gst_number VARCHAR(15),
ADD COLUMN IF NOT EXISTS customer_type VARCHAR(50) DEFAULT 'Individual',
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_farmer_village ON dairy.farmer(village);
CREATE INDEX IF NOT EXISTS idx_farmer_taluka ON dairy.farmer(taluka);
CREATE INDEX IF NOT EXISTS idx_farmer_district ON dairy.farmer(district);
CREATE INDEX IF NOT EXISTS idx_farmer_active ON dairy.farmer(is_active);
CREATE INDEX IF NOT EXISTS idx_customer_city ON dairy.customer(city);
CREATE INDEX IF NOT EXISTS idx_customer_type ON dairy.customer(customer_type);
CREATE INDEX IF NOT EXISTS idx_customer_active ON dairy.customer(is_active);

-- Update existing records to set default values
UPDATE dairy.farmer SET is_active = true WHERE is_active IS NULL;
UPDATE dairy.customer SET is_active = true WHERE is_active IS NULL;
UPDATE dairy.farmer SET created_at = NOW() WHERE created_at IS NULL;
UPDATE dairy.customer SET created_at = NOW() WHERE created_at IS NULL;

-- Sample data updates
UPDATE dairy.farmer SET 
    village = 'Sample Village',
    taluka = 'Sample Taluka', 
    district = 'Sample District',
    state = 'Maharashtra'
WHERE village IS NULL;

UPDATE dairy.customer SET 
    city = 'Sample City',
    state = 'Maharashtra',
    customer_type = 'Individual'
WHERE city IS NULL;