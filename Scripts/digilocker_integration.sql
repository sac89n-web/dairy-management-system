-- Add DigiLocker verification columns to farmer table
ALTER TABLE dairy.farmer 
ADD COLUMN IF NOT EXISTS digilocker_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS digilocker_verified_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS aadhar_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS pan_verified BOOLEAN DEFAULT FALSE;

-- Create DigiLocker verification log table
CREATE TABLE IF NOT EXISTS dairy.digilocker_verification_log (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    document_type VARCHAR(20) NOT NULL, -- 'AADHAR' or 'PAN'
    document_number VARCHAR(50) NOT NULL,
    verification_status BOOLEAN NOT NULL,
    verified_name VARCHAR(255),
    verification_date TIMESTAMP DEFAULT NOW(),
    api_response JSONB
);

-- Update existing farmers with sample DigiLocker verification status
UPDATE dairy.farmer 
SET digilocker_verified = (RANDOM() > 0.3),
    aadhar_verified = (RANDOM() > 0.2),
    pan_verified = (RANDOM() > 0.25)
WHERE id <= 10;

-- Insert sample verification logs
INSERT INTO dairy.digilocker_verification_log (farmer_id, document_type, document_number, verification_status, verified_name)
SELECT 
    f.id,
    'AADHAR',
    f.aadhar_number,
    f.aadhar_verified,
    f.name
FROM dairy.farmer f
WHERE f.id <= 5;

INSERT INTO dairy.digilocker_verification_log (farmer_id, document_type, document_number, verification_status, verified_name)
SELECT 
    f.id,
    'PAN',
    f.pan_number,
    f.pan_verified,
    f.name
FROM dairy.farmer f
WHERE f.id <= 5;