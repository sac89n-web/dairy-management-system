-- Phase 3: KYC, Payments & Notifications Database Schema
-- Run this on your PostgreSQL database

SET search_path TO dairy;

-- KYC verification records table
CREATE TABLE IF NOT EXISTS kyc_verifications (
    id SERIAL PRIMARY KEY,
    farmer_id VARCHAR(20) NOT NULL,
    verification_type VARCHAR(20) NOT NULL, -- 'pan', 'aadhaar', 'bank', 'gst'
    document_number VARCHAR(50) NOT NULL,
    verification_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'verified', 'failed'
    verified_name VARCHAR(100),
    verification_response JSONB,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Payment gateway transactions table
CREATE TABLE IF NOT EXISTS payment_transactions (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(100) UNIQUE NOT NULL,
    farmer_id VARCHAR(20),
    customer_id INTEGER,
    payment_type VARCHAR(20) NOT NULL, -- 'payout', 'collection'
    amount NUMERIC(12,2) NOT NULL,
    charges NUMERIC(8,2) DEFAULT 0,
    payment_method VARCHAR(20) NOT NULL, -- 'UPI', 'NEFT', 'RTGS'
    account_number VARCHAR(50),
    ifsc_code VARCHAR(11),
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'success', 'failed', 'cancelled'
    bank_reference_number VARCHAR(100),
    failure_reason TEXT,
    webhook_data JSONB,
    initiated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Notification logs table
CREATE TABLE IF NOT EXISTS notification_logs (
    id SERIAL PRIMARY KEY,
    recipient_type VARCHAR(20) NOT NULL, -- 'farmer', 'customer', 'admin'
    recipient_id VARCHAR(20) NOT NULL,
    channel VARCHAR(20) NOT NULL, -- 'sms', 'whatsapp', 'email'
    template_type VARCHAR(50) NOT NULL, -- 'collection_receipt', 'payout_notification', 'quality_alert'
    phone_number VARCHAR(15),
    email VARCHAR(100),
    message_content TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'sent', 'delivered', 'failed'
    provider_response JSONB,
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Notification templates table
CREATE TABLE IF NOT EXISTS notification_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL,
    template_type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    language VARCHAR(10) DEFAULT 'en',
    subject VARCHAR(200),
    message_template TEXT NOT NULL,
    variables JSONB, -- Available template variables
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add KYC fields to farmer table
ALTER TABLE farmer 
ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10),
ADD COLUMN IF NOT EXISTS aadhaar_number VARCHAR(12),
ADD COLUMN IF NOT EXISTS gst_number VARCHAR(15),
ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(50),
ADD COLUMN IF NOT EXISTS bank_ifsc_code VARCHAR(11),
ADD COLUMN IF NOT EXISTS kyc_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS kyc_verified_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS bank_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS digilocker_verified BOOLEAN DEFAULT FALSE;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_kyc_verifications_farmer ON kyc_verifications(farmer_id);
CREATE INDEX IF NOT EXISTS idx_kyc_verifications_type ON kyc_verifications(verification_type);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_farmer ON payment_transactions(farmer_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_notification_logs_recipient ON notification_logs(recipient_type, recipient_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_status ON notification_logs(status);
CREATE INDEX IF NOT EXISTS idx_notification_templates_type ON notification_templates(template_type, channel);

-- Insert default notification templates
INSERT INTO notification_templates (template_name, template_type, channel, language, message_template, variables) VALUES
('Collection Receipt Hindi', 'collection_receipt', 'whatsapp', 'hi', 
 'दूध संग्रह रसीद\nकिसान: {{farmer_name}}\nमात्रा: {{quantity}} लीटर\nवसा: {{fat_percentage}}%\nSNF: {{snf_percentage}}%\nदर: ₹{{rate}}/लीटर\nकुल राशि: ₹{{amount}}\nरसीद नं: {{receipt_number}}', 
 '["farmer_name", "quantity", "fat_percentage", "snf_percentage", "rate", "amount", "receipt_number"]'),

('Payout Success Hindi', 'payout_notification', 'whatsapp', 'hi',
 'भुगतान सूचना\nप्रिय {{farmer_name}},\nआपके खाते में ₹{{amount}} जमा किया गया है।\nTransaction ID: {{transaction_id}}\nस्थिति: {{status}}\nदिनांक: {{payout_date}}',
 '["farmer_name", "amount", "transaction_id", "status", "payout_date"]'),

('Quality Alert Hindi', 'quality_alert', 'whatsapp', 'hi',
 'गुणवत्ता चेतावनी\nप्रिय {{farmer_name}},\nआपके दूध की गुणवत्ता में सुधार की आवश्यकता है।\nवसा: {{fat_percentage}}%\nSNF: {{snf_percentage}}%\nसुझाव: {{message}}',
 '["farmer_name", "fat_percentage", "snf_percentage", "message"]')

ON CONFLICT DO NOTHING;

-- Insert sample KYC data
INSERT INTO kyc_verifications (farmer_id, verification_type, document_number, verification_status, verified_name) VALUES
('F001', 'pan', 'ABCDE1234F', 'verified', 'राहुल विनोद पाटील'),
('F001', 'aadhaar', '123456789012', 'verified', 'राहुल विनोद पाटील'),
('F002', 'pan', 'FGHIJ5678K', 'pending', NULL),
('F003', 'bank', '1234567890', 'verified', 'अनिल कुमार')
ON CONFLICT DO NOTHING;