-- Update admin password for Render production database
-- Run this on Render database to sync with local changes

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS dairy;

-- Create users table if not exists
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

-- Insert or update admin user with correct password hash for "admin123"
INSERT INTO dairy.users (username, email, password_hash, role) VALUES
('admin', 'admin@dairy.com', '$2a$11$YourActualHashForAdmin123Password', 1)
ON CONFLICT (username) 
DO UPDATE SET 
    password_hash = '$2a$11$YourActualHashForAdmin123Password',
    updated_at = NOW();

-- Note: Replace '$2a$11$YourActualHashForAdmin123Password' with the actual bcrypt hash
-- that corresponds to password "admin123" from your local database