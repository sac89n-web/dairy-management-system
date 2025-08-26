-- Enhanced Master Data Tables Script
-- Run this script to update existing tables with new fields

-- =====================================================
-- FARMER TABLE ENHANCEMENTS
-- =====================================================

-- Add new columns to farmer table
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

-- =====================================================
-- CUSTOMER TABLE ENHANCEMENTS
-- =====================================================

-- Add new columns to customer table
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

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Farmer table indexes
CREATE INDEX IF NOT EXISTS idx_farmer_village ON dairy.farmer(village);
CREATE INDEX IF NOT EXISTS idx_farmer_taluka ON dairy.farmer(taluka);
CREATE INDEX IF NOT EXISTS idx_farmer_district ON dairy.farmer(district);
CREATE INDEX IF NOT EXISTS idx_farmer_active ON dairy.farmer(is_active);
CREATE INDEX IF NOT EXISTS idx_farmer_code ON dairy.farmer(code);
CREATE INDEX IF NOT EXISTS idx_farmer_contact ON dairy.farmer(contact);
CREATE INDEX IF NOT EXISTS idx_farmer_aadhar ON dairy.farmer(aadhar_number);
CREATE INDEX IF NOT EXISTS idx_farmer_pan ON dairy.farmer(pan_number);

-- Customer table indexes
CREATE INDEX IF NOT EXISTS idx_customer_city ON dairy.customer(city);
CREATE INDEX IF NOT EXISTS idx_customer_type ON dairy.customer(customer_type);
CREATE INDEX IF NOT EXISTS idx_customer_active ON dairy.customer(is_active);
CREATE INDEX IF NOT EXISTS idx_customer_contact ON dairy.customer(contact);
CREATE INDEX IF NOT EXISTS idx_customer_gst ON dairy.customer(gst_number);

-- =====================================================
-- DATA MIGRATION & DEFAULTS
-- =====================================================

-- Update existing records with default values
UPDATE dairy.farmer SET 
    is_active = true,
    created_at = COALESCE(created_at, NOW()),
    updated_at = NOW(),
    state = COALESCE(state, 'Maharashtra')
WHERE is_active IS NULL OR created_at IS NULL;

UPDATE dairy.customer SET 
    is_active = true,
    created_at = COALESCE(created_at, NOW()),
    updated_at = NOW(),
    state = COALESCE(state, 'Maharashtra'),
    customer_type = COALESCE(customer_type, 'Individual')
WHERE is_active IS NULL OR created_at IS NULL;

-- =====================================================
-- SAMPLE DATA UPDATES (Optional)
-- =====================================================

-- Update existing farmers with sample location data
UPDATE dairy.farmer SET 
    village = COALESCE(village, 'Village-' || id),
    taluka = COALESCE(taluka, 'Taluka-' || (id % 10 + 1)),
    district = COALESCE(district, 'District-' || (id % 5 + 1)),
    state = 'Maharashtra'
WHERE village IS NULL OR taluka IS NULL OR district IS NULL;

-- Update existing customers with sample city data
UPDATE dairy.customer SET 
    city = COALESCE(city, 'City-' || id),
    state = 'Maharashtra',
    customer_type = COALESCE(customer_type, 'Individual')
WHERE city IS NULL;

-- =====================================================
-- CONSTRAINTS & VALIDATIONS
-- =====================================================

-- Add check constraints for data validation (drop if exists first)
DO $$ 
BEGIN
    -- Farmer constraints
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_farmer_pincode') THEN
        ALTER TABLE dairy.farmer ADD CONSTRAINT chk_farmer_pincode 
        CHECK (pincode IS NULL OR LENGTH(pincode) = 6);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_farmer_aadhar') THEN
        ALTER TABLE dairy.farmer ADD CONSTRAINT chk_farmer_aadhar 
        CHECK (aadhar_number IS NULL OR LENGTH(aadhar_number) = 12);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_farmer_pan') THEN
        ALTER TABLE dairy.farmer ADD CONSTRAINT chk_farmer_pan 
        CHECK (pan_number IS NULL OR LENGTH(pan_number) = 10);
    END IF;
    
    -- Customer constraints
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_customer_pincode') THEN
        ALTER TABLE dairy.customer ADD CONSTRAINT chk_customer_pincode 
        CHECK (pincode IS NULL OR LENGTH(pincode) = 6);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_customer_gst') THEN
        ALTER TABLE dairy.customer ADD CONSTRAINT chk_customer_gst 
        CHECK (gst_number IS NULL OR LENGTH(gst_number) = 15);
    END IF;
END $$;

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for farmer table
DROP TRIGGER IF EXISTS update_farmer_updated_at ON dairy.farmer;
CREATE TRIGGER update_farmer_updated_at 
    BEFORE UPDATE ON dairy.farmer 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Triggers for customer table
DROP TRIGGER IF EXISTS update_customer_updated_at ON dairy.customer;
CREATE TRIGGER update_customer_updated_at 
    BEFORE UPDATE ON dairy.customer 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify farmer table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_schema = 'dairy' AND table_name = 'farmer'
ORDER BY ordinal_position;

-- Verify customer table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_schema = 'dairy' AND table_name = 'customer'
ORDER BY ordinal_position;

-- Count active records
SELECT 
    'Farmers' as entity,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE is_active = true) as active_count
FROM dairy.farmer
UNION ALL
SELECT 
    'Customers' as entity,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE is_active = true) as active_count
FROM dairy.customer;

-- =====================================================
-- UNIQUE CONSTRAINTS
-- =====================================================

-- Add unique constraints for farmer code and contact
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_farmer_code') THEN
        ALTER TABLE dairy.farmer ADD CONSTRAINT uk_farmer_code UNIQUE (code);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_customer_contact') THEN
        ALTER TABLE dairy.customer ADD CONSTRAINT uk_customer_contact UNIQUE (contact);
    END IF;
EXCEPTION
    WHEN duplicate_object THEN
        NULL; -- Ignore if constraint already exists
END $$;

-- =====================================================
-- SAMPLE INSERT STATEMENTS (Optional)
-- =====================================================

-- Sample farmer insert (uncomment to use)
-- INSERT INTO dairy.farmer (
--     name, code, contact, email, address, village, taluka, district, state, pincode,
--     bank_name, account_number, ifsc_code, aadhar_number, pan_number, branch_id
-- ) VALUES (
--     'राम शर्मा', 'F001', '9876543210', 'ram.sharma@example.com', 
--     'गांव रोड, मुख्य चौक के पास', 'रामपुर', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412208',
--     'State Bank of India', '12345678901234', 'SBIN0001234', '123456789012', 'ABCDE1234F', 1
-- ) ON CONFLICT (code) DO NOTHING;

-- Sample customer insert (uncomment to use)
-- INSERT INTO dairy.customer (
--     name, contact, email, address, city, state, pincode, 
--     gst_number, customer_type, branch_id
-- ) VALUES (
--     'सुनील ट्रेडर्स', '9876543211', 'sunil.traders@example.com',
--     'मार्केट यार्ड, दुकान नं. 15', 'पुणे', 'महाराष्ट्र', '411001',
--     '27ABCDE1234F1Z5', 'Retailer', 1
-- ) ON CONFLICT (contact) DO NOTHING;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Enhanced Master Data Tables Script Completed Successfully!';
    RAISE NOTICE 'Farmer table enhanced with % new columns', 
        (SELECT COUNT(*) FROM information_schema.columns 
         WHERE table_schema = 'dairy' AND table_name = 'farmer');
    RAISE NOTICE 'Customer table enhanced with % new columns', 
        (SELECT COUNT(*) FROM information_schema.columns 
         WHERE table_schema = 'dairy' AND table_name = 'customer');
END $$;