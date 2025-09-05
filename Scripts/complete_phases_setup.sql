-- Complete Database Setup for All Phases
-- Run this on your PostgreSQL database

SET search_path TO dairy;

-- Phase 2: Hardware Integration Tables
CREATE TABLE IF NOT EXISTS hardware_devices (
    device_id VARCHAR(50) PRIMARY KEY,
    device_type VARCHAR(20) NOT NULL,
    port_name VARCHAR(10) NOT NULL,
    baud_rate INTEGER DEFAULT 9600,
    is_connected BOOLEAN DEFAULT FALSE,
    last_connected TIMESTAMP,
    configuration JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rfid_cards (
    card_id VARCHAR(50) PRIMARY KEY,
    farmer_id VARCHAR(20) NOT NULL,
    farmer_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    last_used TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hardware_sessions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(50) UNIQUE NOT NULL,
    farmer_id VARCHAR(20),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    weight_readings JSONB,
    quality_readings JSONB,
    final_collection_id INTEGER,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Users and Security Tables
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    mobile VARCHAR(15),
    role INTEGER NOT NULL DEFAULT 3,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP,
    created_by INTEGER
);

-- Insert default admin user
INSERT INTO users (username, email, password_hash, full_name, role, created_by) VALUES
('admin', 'admin@dairy.com', 'jGl25bVBBBW96Qi9Te4V37Fnqchz/Eu4qB9vKrRIqRg=', 'System Administrator', 1, 1)
ON CONFLICT (username) DO NOTHING;

-- Phase 3: KYC, Payments & Notifications Tables
CREATE TABLE IF NOT EXISTS kyc_verifications (
    id SERIAL PRIMARY KEY,
    farmer_id VARCHAR(20) NOT NULL,
    verification_type VARCHAR(20) NOT NULL,
    document_number VARCHAR(50) NOT NULL,
    verification_status VARCHAR(20) DEFAULT 'pending',
    verified_name VARCHAR(100),
    verification_response JSONB,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment_transactions (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(100) UNIQUE NOT NULL,
    farmer_id VARCHAR(20),
    customer_id INTEGER,
    payment_type VARCHAR(20) NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    charges NUMERIC(8,2) DEFAULT 0,
    payment_method VARCHAR(20) NOT NULL,
    account_number VARCHAR(50),
    ifsc_code VARCHAR(11),
    status VARCHAR(20) DEFAULT 'pending',
    bank_reference_number VARCHAR(100),
    failure_reason TEXT,
    webhook_data JSONB,
    initiated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_logs (
    id SERIAL PRIMARY KEY,
    recipient_type VARCHAR(20) NOT NULL,
    recipient_id VARCHAR(20) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    template_type VARCHAR(50) NOT NULL,
    phone_number VARCHAR(15),
    email VARCHAR(100),
    message_content TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    provider_response JSONB,
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL,
    template_type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    language VARCHAR(10) DEFAULT 'en',
    subject VARCHAR(200),
    message_template TEXT NOT NULL,
    variables JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add missing columns to existing tables
ALTER TABLE milk_collection 
ADD COLUMN IF NOT EXISTS density NUMERIC(6,3),
ADD COLUMN IF NOT EXISTS temperature NUMERIC(4,1),
ADD COLUMN IF NOT EXISTS session_id VARCHAR(50),
ADD COLUMN IF NOT EXISTS rfid_card_id VARCHAR(50),
ADD COLUMN IF NOT EXISTS snf_pct NUMERIC(4,2);

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

-- Insert sample data
INSERT INTO hardware_devices (device_id, device_type, port_name, baud_rate) VALUES
('SCALE_001', 'scale', 'COM1', 9600),
('ANALYZER_001', 'analyzer', 'COM2', 9600),
('PRINTER_001', 'printer', 'COM3', 9600),
('RFID_001', 'rfid', 'COM4', 9600)
ON CONFLICT (device_id) DO NOTHING;

INSERT INTO rfid_cards (card_id, farmer_id, farmer_name) VALUES
('CARD001', 'F001', 'राहुल पाटील'),
('CARD002', 'F002', 'सुनील शर्मा'),
('CARD003', 'F003', 'अनिल कुमार')
ON CONFLICT (card_id) DO NOTHING;

INSERT INTO notification_templates (template_name, template_type, channel, language, message_template, variables) VALUES
('Collection Receipt Hindi', 'collection_receipt', 'whatsapp', 'hi', 
 'दूध संग्रह रसीद\nकिसान: {{farmer_name}}\nमात्रा: {{quantity}} लीटर\nवसा: {{fat_percentage}}%\nSNF: {{snf_percentage}}%\nदर: ₹{{rate}}/लीटर\nकुल राशि: ₹{{amount}}\nरसीद नं: {{receipt_number}}', 
 '["farmer_name", "quantity", "fat_percentage", "snf_percentage", "rate", "amount", "receipt_number"]'),
('Payout Success Hindi', 'payout_notification', 'whatsapp', 'hi',
 'भुगतान सूचना\nप्रिय {{farmer_name}},\nआपके खाते में ₹{{amount}} जमा किया गया है।\nTransaction ID: {{transaction_id}}\nस्थिति: {{status}}\nदिनांक: {{payout_date}}',
 '["farmer_name", "amount", "transaction_id", "status", "payout_date"]')
ON CONFLICT DO NOTHING;