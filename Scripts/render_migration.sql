-- Direct SQL to sync admin password on Render
-- Execute this on Render database console

CREATE SCHEMA IF NOT EXISTS dairy;

CREATE TABLE IF NOT EXISTS dairy.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert admin with bcrypt hash for "admin123"
INSERT INTO dairy.users (username, email, password_hash, role) VALUES
('admin', 'admin@dairy.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj3bp.gSInG2', 1)
ON CONFLICT (username) 
DO UPDATE SET 
    password_hash = '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj3bp.gSInG2',
    updated_at = NOW();