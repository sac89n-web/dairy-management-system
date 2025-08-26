-- Add SNF column to milk_collection table if it doesn't exist
ALTER TABLE dairy.milk_collection 
ADD COLUMN IF NOT EXISTS snf_pct DECIMAL(5,2) DEFAULT 8.5;

-- Update existing records with default SNF values
UPDATE dairy.milk_collection 
SET snf_pct = 8.5 + (fat_pct * 0.25) 
WHERE snf_pct IS NULL;