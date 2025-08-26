-- Railway PostgreSQL initialization script
-- This will be run automatically when PostgreSQL service starts

-- Create dairy schema
CREATE SCHEMA IF NOT EXISTS dairy;

-- Set search path
SET search_path TO dairy, public;

-- Create basic tables for Railway deployment
CREATE TABLE IF NOT EXISTS dairy.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin user (password: admin123)
INSERT INTO dairy.users (username, password_hash, role) 
VALUES ('admin', '$2a$11$8K1p/a0dURXAm/3f62tE7uxzanO.nnOhX0ttHBHp1WiUQOAEMAzAm', 'admin')
ON CONFLICT (username) DO NOTHING;

-- Create milk_collections table
CREATE TABLE IF NOT EXISTS dairy.milk_collections (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER,
    quantity DECIMAL(10,2) NOT NULL,
    fat_percentage DECIMAL(5,2),
    snf_percentage DECIMAL(5,2),
    collection_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sales table
CREATE TABLE IF NOT EXISTS dairy.sales (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    quantity DECIMAL(10,2) NOT NULL,
    price_per_liter DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    sale_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA dairy TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dairy TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dairy TO PUBLIC;