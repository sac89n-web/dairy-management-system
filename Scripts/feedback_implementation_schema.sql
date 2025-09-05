-- Feedback Implementation: Priority Features Database Schema
-- Based on Ramesh Ghodake's feedback for competitive dairy management system

SET search_path TO dairy;

-- Payment Cycles Table (10-day cycles)
CREATE TABLE IF NOT EXISTS payment_cycles (
    id SERIAL PRIMARY KEY,
    cycle_name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'processing', 'completed'
    total_farmers INTEGER DEFAULT 0,
    total_amount NUMERIC(15,2) DEFAULT 0,
    processed_farmers INTEGER DEFAULT 0,
    bank_file_generated BOOLEAN DEFAULT FALSE,
    bank_file_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Payment Cycle Details (per farmer in each cycle)
CREATE TABLE IF NOT EXISTS payment_cycle_details (
    id SERIAL PRIMARY KEY,
    cycle_id INTEGER REFERENCES payment_cycles(id),
    farmer_id INTEGER REFERENCES farmer(id),
    total_milk_qty NUMERIC(10,2) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    advance_deduction NUMERIC(10,2) DEFAULT 0,
    bonus_amount NUMERIC(10,2) DEFAULT 0,
    final_amount NUMERIC(12,2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processed', 'paid', 'failed'
    payment_method VARCHAR(20), -- 'bank_transfer', 'cash', 'upi'
    transaction_reference VARCHAR(100),
    invoice_generated BOOLEAN DEFAULT FALSE,
    invoice_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    paid_at TIMESTAMP
);

-- Bonus Configuration
CREATE TABLE IF NOT EXISTS bonus_configurations (
    id SERIAL PRIMARY KEY,
    config_name VARCHAR(100) NOT NULL,
    bonus_type VARCHAR(20) NOT NULL, -- 'quantity', 'quality', 'consistency', 'combined'
    calculation_method VARCHAR(20) NOT NULL, -- 'percentage', 'slab', 'fixed'
    criteria JSONB NOT NULL, -- Flexible criteria storage
    is_active BOOLEAN DEFAULT TRUE,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Bonus Calculations (per farmer per period)
CREATE TABLE IF NOT EXISTS bonus_calculations (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES farmer(id),
    config_id INTEGER REFERENCES bonus_configurations(id),
    calculation_period VARCHAR(20) NOT NULL, -- 'half_yearly', 'yearly'
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_milk_qty NUMERIC(12,2) NOT NULL,
    avg_fat_pct NUMERIC(4,2),
    avg_snf_pct NUMERIC(4,2),
    consistency_score NUMERIC(4,2), -- Days supplied / Total days
    bonus_amount NUMERIC(12,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'calculated', -- 'calculated', 'approved', 'paid'
    approved_by INTEGER REFERENCES employee(id),
    paid_in_cycle_id INTEGER REFERENCES payment_cycles(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Advance/Loan Management
CREATE TABLE IF NOT EXISTS farmer_advances (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES farmer(id),
    amount NUMERIC(12,2) NOT NULL,
    purpose VARCHAR(100),
    disbursed_date DATE NOT NULL,
    total_installments INTEGER DEFAULT 1,
    installment_amount NUMERIC(10,2),
    remaining_amount NUMERIC(12,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'written_off'
    approved_by INTEGER REFERENCES employee(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Advance Deductions (tracked per payment cycle)
CREATE TABLE IF NOT EXISTS advance_deductions (
    id SERIAL PRIMARY KEY,
    advance_id INTEGER REFERENCES farmer_advances(id),
    cycle_id INTEGER REFERENCES payment_cycles(id),
    deduction_amount NUMERIC(10,2) NOT NULL,
    remaining_balance NUMERIC(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Bank Integration for Corporate Uploads
CREATE TABLE IF NOT EXISTS bank_upload_batches (
    id SERIAL PRIMARY KEY,
    cycle_id INTEGER REFERENCES payment_cycles(id),
    bank_name VARCHAR(50) NOT NULL, -- 'SBI', 'ICICI', 'HDFC'
    file_format VARCHAR(10) NOT NULL, -- 'CSV', 'XML', 'TXT'
    file_path VARCHAR(255) NOT NULL,
    total_records INTEGER NOT NULL,
    total_amount NUMERIC(15,2) NOT NULL,
    upload_status VARCHAR(20) DEFAULT 'generated', -- 'generated', 'uploaded', 'processed', 'failed'
    bank_reference VARCHAR(100),
    uploaded_at TIMESTAMP,
    processed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Notification System Enhancement
CREATE TABLE IF NOT EXISTS notification_preferences (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES farmer(id),
    sms_enabled BOOLEAN DEFAULT TRUE,
    whatsapp_enabled BOOLEAN DEFAULT TRUE,
    email_enabled BOOLEAN DEFAULT FALSE,
    language_preference VARCHAR(10) DEFAULT 'hi', -- 'hi', 'en', 'mr'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Alert System for Quality, Payments, etc.
CREATE TABLE IF NOT EXISTS system_alerts (
    id SERIAL PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL, -- 'quality_low', 'payment_due', 'irregular_supply', 'low_stock'
    severity VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    entity_type VARCHAR(20) NOT NULL, -- 'farmer', 'customer', 'inventory', 'system'
    entity_id INTEGER,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_by INTEGER REFERENCES employee(id),
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Enhanced Reporting Tables
CREATE TABLE IF NOT EXISTS report_schedules (
    id SERIAL PRIMARY KEY,
    report_name VARCHAR(100) NOT NULL,
    report_type VARCHAR(50) NOT NULL, -- 'daily', 'weekly', 'monthly', 'cycle_summary'
    recipients JSONB NOT NULL, -- Email addresses, phone numbers
    schedule_cron VARCHAR(50) NOT NULL, -- Cron expression
    parameters JSONB, -- Report parameters
    is_active BOOLEAN DEFAULT TRUE,
    last_run TIMESTAMP,
    next_run TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add missing columns to existing tables
ALTER TABLE milk_collection 
ADD COLUMN IF NOT EXISTS snf_pct NUMERIC(4,2),
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS cycle_id INTEGER REFERENCES payment_cycles(id);

ALTER TABLE farmer 
ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(50),
ADD COLUMN IF NOT EXISTS bank_ifsc_code VARCHAR(11),
ADD COLUMN IF NOT EXISTS upi_id VARCHAR(100),
ADD COLUMN IF NOT EXISTS preferred_payment_method VARCHAR(20) DEFAULT 'bank_transfer';

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_cycles_dates ON payment_cycles(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_payment_cycle_details_farmer ON payment_cycle_details(farmer_id, cycle_id);
CREATE INDEX IF NOT EXISTS idx_bonus_calculations_farmer ON bonus_calculations(farmer_id, period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_farmer_advances_status ON farmer_advances(farmer_id, status);
CREATE INDEX IF NOT EXISTS idx_system_alerts_unresolved ON system_alerts(alert_type, is_resolved);
CREATE INDEX IF NOT EXISTS idx_milk_collection_cycle ON milk_collection(cycle_id);

-- Insert sample bonus configurations
INSERT INTO bonus_configurations (config_name, bonus_type, calculation_method, criteria, effective_from) VALUES
('Quality Bonus - Half Yearly', 'quality', 'slab', 
 '{"fat_min": 3.5, "snf_min": 8.5, "slabs": [{"min_qty": 1000, "bonus_pct": 2}, {"min_qty": 2000, "bonus_pct": 5}]}', 
 CURRENT_DATE),
('Consistency Bonus - Yearly', 'consistency', 'percentage', 
 '{"min_days": 300, "bonus_pct": 3, "max_bonus": 10000}', 
 CURRENT_DATE),
('Volume Bonus - Half Yearly', 'quantity', 'slab', 
 '{"slabs": [{"min_qty": 5000, "bonus_pct": 1}, {"min_qty": 10000, "bonus_pct": 3}, {"min_qty": 20000, "bonus_pct": 5}]}', 
 CURRENT_DATE)
ON CONFLICT DO NOTHING;

-- Insert notification templates for new features
INSERT INTO notification_templates (template_name, template_type, channel, language, message_template, variables) VALUES
('Payment Cycle Notification', 'payment_cycle', 'whatsapp', 'hi',
 'भुगतान चक्र सूचना\nप्रिय {{farmer_name}},\n10-दिन का भुगतान चक्र पूरा हुआ\nकुल दूध: {{total_qty}} लीटर\nकुल राशि: ₹{{total_amount}}\nअग्रिम कटौती: ₹{{advance_deduction}}\nअंतिम राशि: ₹{{final_amount}}\nभुगतान स्थिति: {{payment_status}}',
 '["farmer_name", "total_qty", "total_amount", "advance_deduction", "final_amount", "payment_status"]'),

('Bonus Notification', 'bonus_payout', 'whatsapp', 'hi',
 'बोनस सूचना\nबधाई हो {{farmer_name}}!\nआपको {{period}} के लिए ₹{{bonus_amount}} बोनस मिला है\nकारण: {{bonus_reason}}\nकुल दूध आपूर्ति: {{total_supply}} लीटर\nगुणवत्ता स्कोर: {{quality_score}}',
 '["farmer_name", "period", "bonus_amount", "bonus_reason", "total_supply", "quality_score"]'),

('Quality Alert', 'quality_alert', 'whatsapp', 'hi',
 'गुणवत्ता चेतावनी\n{{farmer_name}},\nपिछले 3 दिनों में आपके दूध की गुणवत्ता कम है:\nवसा: {{avg_fat}}% (न्यूनतम: 3.5%)\nSNF: {{avg_snf}}% (न्यूनतम: 8.5%)\nसुधार के लिए संपर्क करें',
 '["farmer_name", "avg_fat", "avg_snf"]')
ON CONFLICT DO NOTHING;