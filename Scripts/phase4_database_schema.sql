-- Phase 4: Advanced Analytics & Enterprise Features Database Schema
-- Run this on your PostgreSQL database

SET search_path TO dairy;

-- Analytics and BI Tables
CREATE TABLE IF NOT EXISTS analytics_metrics (
    id SERIAL PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_value NUMERIC(15,4) NOT NULL,
    metric_type VARCHAR(50) NOT NULL, -- 'daily', 'weekly', 'monthly', 'yearly'
    category VARCHAR(50) NOT NULL, -- 'production', 'quality', 'financial', 'farmer'
    date_recorded DATE NOT NULL,
    branch_id INTEGER,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS predictive_models (
    id SERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    model_type VARCHAR(50) NOT NULL, -- 'quality_prediction', 'price_forecast', 'demand_forecast'
    model_data JSONB NOT NULL,
    accuracy_score NUMERIC(5,4),
    last_trained TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Multi-Branch Management Tables
CREATE TABLE IF NOT EXISTS branches (
    id SERIAL PRIMARY KEY,
    branch_code VARCHAR(20) UNIQUE NOT NULL,
    branch_name VARCHAR(100) NOT NULL,
    parent_branch_id INTEGER REFERENCES branches(id),
    branch_type VARCHAR(30) NOT NULL, -- 'head_office', 'regional', 'collection_center'
    address TEXT,
    contact_person VARCHAR(100),
    phone VARCHAR(15),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inter_branch_transfers (
    id SERIAL PRIMARY KEY,
    transfer_number VARCHAR(50) UNIQUE NOT NULL,
    from_branch_id INTEGER REFERENCES branches(id),
    to_branch_id INTEGER REFERENCES branches(id),
    transfer_type VARCHAR(30) NOT NULL, -- 'milk', 'inventory', 'cash'
    quantity NUMERIC(10,2),
    amount NUMERIC(12,2),
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'in_transit', 'completed', 'cancelled'
    transfer_date DATE NOT NULL,
    received_date DATE,
    notes TEXT,
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Mobile App Integration Tables
CREATE TABLE IF NOT EXISTS mobile_app_users (
    id SERIAL PRIMARY KEY,
    user_type VARCHAR(20) NOT NULL, -- 'farmer', 'field_officer', 'admin'
    farmer_id INTEGER,
    employee_id INTEGER,
    device_id VARCHAR(100) UNIQUE,
    app_version VARCHAR(20),
    fcm_token VARCHAR(255), -- For push notifications
    last_sync TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mobile_sync_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES mobile_app_users(id),
    sync_type VARCHAR(30) NOT NULL, -- 'collection', 'payment', 'farmer_data'
    records_synced INTEGER DEFAULT 0,
    sync_status VARCHAR(20) DEFAULT 'success', -- 'success', 'partial', 'failed'
    error_message TEXT,
    sync_timestamp TIMESTAMP DEFAULT NOW()
);

-- AI/ML Features Tables
CREATE TABLE IF NOT EXISTS ml_predictions (
    id SERIAL PRIMARY KEY,
    prediction_type VARCHAR(50) NOT NULL, -- 'quality_score', 'price_forecast', 'fraud_detection'
    entity_type VARCHAR(30) NOT NULL, -- 'farmer', 'collection', 'payment'
    entity_id INTEGER NOT NULL,
    predicted_value NUMERIC(10,4),
    confidence_score NUMERIC(5,4),
    actual_value NUMERIC(10,4), -- For model accuracy tracking
    prediction_date TIMESTAMP DEFAULT NOW(),
    model_version VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS fraud_alerts (
    id SERIAL PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL, -- 'quality_manipulation', 'duplicate_collection', 'suspicious_payment'
    entity_type VARCHAR(30) NOT NULL,
    entity_id INTEGER NOT NULL,
    risk_score NUMERIC(5,4) NOT NULL,
    alert_details JSONB,
    status VARCHAR(20) DEFAULT 'open', -- 'open', 'investigating', 'resolved', 'false_positive'
    assigned_to INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);

-- Supply Chain Integration Tables
CREATE TABLE IF NOT EXISTS vendors (
    id SERIAL PRIMARY KEY,
    vendor_code VARCHAR(20) UNIQUE NOT NULL,
    vendor_name VARCHAR(100) NOT NULL,
    vendor_type VARCHAR(30) NOT NULL, -- 'feed_supplier', 'equipment', 'packaging', 'transport'
    contact_person VARCHAR(100),
    phone VARCHAR(15),
    email VARCHAR(100),
    address TEXT,
    gst_number VARCHAR(15),
    payment_terms VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS procurement_orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    vendor_id INTEGER REFERENCES vendors(id),
    branch_id INTEGER REFERENCES branches(id),
    order_date DATE NOT NULL,
    expected_delivery DATE,
    total_amount NUMERIC(12,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'delivered', 'cancelled'
    created_by INTEGER,
    approved_by INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS procurement_order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES procurement_orders(id),
    item_name VARCHAR(100) NOT NULL,
    quantity NUMERIC(10,2) NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    total_price NUMERIC(12,2) NOT NULL,
    received_quantity NUMERIC(10,2) DEFAULT 0
);

CREATE TABLE IF NOT EXISTS logistics_tracking (
    id SERIAL PRIMARY KEY,
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    shipment_type VARCHAR(30) NOT NULL, -- 'milk_collection', 'procurement', 'inter_branch'
    reference_id INTEGER NOT NULL, -- Links to collection, order, or transfer
    from_location VARCHAR(100),
    to_location VARCHAR(100),
    vehicle_number VARCHAR(20),
    driver_name VARCHAR(100),
    driver_phone VARCHAR(15),
    status VARCHAR(20) DEFAULT 'dispatched', -- 'dispatched', 'in_transit', 'delivered'
    dispatch_time TIMESTAMP,
    delivery_time TIMESTAMP,
    gps_coordinates JSONB, -- Real-time location tracking
    created_at TIMESTAMP DEFAULT NOW()
);

-- Cloud & Scalability Tables
CREATE TABLE IF NOT EXISTS system_performance (
    id SERIAL PRIMARY KEY,
    metric_name VARCHAR(50) NOT NULL, -- 'cpu_usage', 'memory_usage', 'db_connections', 'response_time'
    metric_value NUMERIC(10,4) NOT NULL,
    server_instance VARCHAR(50),
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_trails (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INTEGER,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(100),
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Add branch_id to existing tables for multi-branch support
ALTER TABLE farmer ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
ALTER TABLE customer ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
ALTER TABLE milk_collection ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
ALTER TABLE sale ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_analytics_metrics_date ON analytics_metrics(date_recorded);
CREATE INDEX IF NOT EXISTS idx_analytics_metrics_category ON analytics_metrics(category);
CREATE INDEX IF NOT EXISTS idx_branches_parent ON branches(parent_branch_id);
CREATE INDEX IF NOT EXISTS idx_transfers_branches ON inter_branch_transfers(from_branch_id, to_branch_id);
CREATE INDEX IF NOT EXISTS idx_ml_predictions_type ON ml_predictions(prediction_type, entity_type);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_status ON fraud_alerts(status);
CREATE INDEX IF NOT EXISTS idx_logistics_status ON logistics_tracking(status);
CREATE INDEX IF NOT EXISTS idx_audit_trails_user ON audit_trails(user_id, timestamp);

-- Insert sample data
INSERT INTO branches (branch_code, branch_name, branch_type, address, contact_person, phone) VALUES
('HO001', 'Head Office', 'head_office', 'Mumbai, Maharashtra', 'Rajesh Kumar', '9876543210'),
('RG001', 'Western Region', 'regional', 'Pune, Maharashtra', 'Suresh Patil', '9876543211'),
('CC001', 'Village Collection Center 1', 'collection_center', 'Satara, Maharashtra', 'Ramesh Farmer', '9876543212'),
('CC002', 'Village Collection Center 2', 'collection_center', 'Kolhapur, Maharashtra', 'Ganesh Dairy', '9876543213')
ON CONFLICT (branch_code) DO NOTHING;

INSERT INTO vendors (vendor_code, vendor_name, vendor_type, contact_person, phone) VALUES
('VND001', 'Maharashtra Feed Suppliers', 'feed_supplier', 'Anil Agarwal', '9876543220'),
('VND002', 'Dairy Equipment Co.', 'equipment', 'Prakash Industries', '9876543221'),
('VND003', 'Packaging Solutions Ltd.', 'packaging', 'Ravi Packaging', '9876543222'),
('VND004', 'Logistics Transport', 'transport', 'Transport Singh', '9876543223')
ON CONFLICT (vendor_code) DO NOTHING;

-- Insert sample analytics metrics
INSERT INTO analytics_metrics (metric_name, metric_value, metric_type, category, date_recorded, branch_id) VALUES
('daily_milk_collection', 15000.50, 'daily', 'production', CURRENT_DATE, 1),
('average_fat_percentage', 4.2, 'daily', 'quality', CURRENT_DATE, 1),
('daily_revenue', 450000.00, 'daily', 'financial', CURRENT_DATE, 1),
('active_farmers', 150, 'daily', 'farmer', CURRENT_DATE, 1),
('collection_efficiency', 95.5, 'daily', 'production', CURRENT_DATE, 1)
ON CONFLICT DO NOTHING;