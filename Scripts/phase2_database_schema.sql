-- Phase 2: Hardware Integration Database Schema
-- Run this on your PostgreSQL database

SET search_path TO dairy;

-- Hardware devices configuration table
CREATE TABLE IF NOT EXISTS hardware_devices (
    device_id VARCHAR(50) PRIMARY KEY,
    device_type VARCHAR(20) NOT NULL, -- 'scale', 'analyzer', 'printer', 'rfid'
    port_name VARCHAR(10) NOT NULL,
    baud_rate INTEGER DEFAULT 9600,
    is_connected BOOLEAN DEFAULT FALSE,
    last_connected TIMESTAMP,
    configuration JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- RFID cards for farmer identification
CREATE TABLE IF NOT EXISTS rfid_cards (
    card_id VARCHAR(50) PRIMARY KEY,
    farmer_id VARCHAR(20) NOT NULL,
    farmer_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    last_used TIMESTAMP
);

-- Add hardware-specific columns to milk_collection table
ALTER TABLE milk_collection 
ADD COLUMN IF NOT EXISTS density NUMERIC(6,3),
ADD COLUMN IF NOT EXISTS temperature NUMERIC(4,1),
ADD COLUMN IF NOT EXISTS session_id VARCHAR(50),
ADD COLUMN IF NOT EXISTS rfid_card_id VARCHAR(50),
ADD COLUMN IF NOT EXISTS snf_pct NUMERIC(4,2);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_hardware_devices_type ON hardware_devices(device_type);
CREATE INDEX IF NOT EXISTS idx_rfid_cards_farmer ON rfid_cards(farmer_id);
CREATE INDEX IF NOT EXISTS idx_milk_collection_session ON milk_collection(session_id);
CREATE INDEX IF NOT EXISTS idx_milk_collection_rfid ON milk_collection(rfid_card_id);

-- Insert sample hardware devices
INSERT INTO hardware_devices (device_id, device_type, port_name, baud_rate) VALUES
('SCALE_001', 'scale', 'COM1', 9600),
('ANALYZER_001', 'analyzer', 'COM2', 9600),
('PRINTER_001', 'printer', 'COM3', 9600),
('RFID_001', 'rfid', 'COM4', 9600)
ON CONFLICT (device_id) DO NOTHING;

-- Insert sample RFID cards
INSERT INTO rfid_cards (card_id, farmer_id, farmer_name) VALUES
('CARD001', 'F001', 'राहुल पाटील'),
('CARD002', 'F002', 'सुनील शर्मा'),
('CARD003', 'F003', 'अनिल कुमार')
ON CONFLICT (card_id) DO NOTHING;

-- Create hardware session log table
CREATE TABLE IF NOT EXISTS hardware_sessions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(50) UNIQUE NOT NULL,
    farmer_id VARCHAR(20),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    weight_readings JSONB,
    quality_readings JSONB,
    final_collection_id INTEGER REFERENCES milk_collection(id),
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'cancelled'
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hardware_sessions_farmer ON hardware_sessions(farmer_id);
CREATE INDEX IF NOT EXISTS idx_hardware_sessions_status ON hardware_sessions(status);