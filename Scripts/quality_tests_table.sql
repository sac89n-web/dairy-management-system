-- Create quality_tests table for quality control functionality

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
    remarks TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_quality_tests_batch_id ON dairy.quality_tests(batch_id);
CREATE INDEX IF NOT EXISTS idx_quality_tests_test_date ON dairy.quality_tests(test_date);
CREATE INDEX IF NOT EXISTS idx_quality_tests_fssai_compliant ON dairy.quality_tests(fssai_compliant);

-- Insert sample data
INSERT INTO dairy.quality_tests (batch_id, fat_pct, snf_pct, bacterial_count, fssai_compliant) VALUES
(1, 4.2, 8.5, 50000, true),
(2, 3.8, 8.2, 45000, true),
(3, 4.5, 8.8, 30000, true),
(4, 3.5, 8.0, 60000, false),
(5, 4.0, 8.3, 40000, true);