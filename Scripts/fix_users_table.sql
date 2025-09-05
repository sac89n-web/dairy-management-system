-- Fix users table schema issue
-- This script creates the missing users table with the required full_name column

SET search_path TO dairy;

-- Create users table if it doesn't exist (for compatibility)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL DEFAULT 'User',
    is_active BOOLEAN DEFAULT TRUE,
    branch_id INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert default admin user if not exists
INSERT INTO users (username, email, full_name, password_hash, role, is_active) 
VALUES ('admin', 'admin@dairy.com', 'System Administrator', '$2a$11$dummy.hash.for.admin.user', 'Admin', TRUE)
ON CONFLICT (username) DO NOTHING;

-- Add foreign key constraint for branch_id if branches table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'dairy' AND table_name = 'branches') THEN
        ALTER TABLE users ADD CONSTRAINT fk_users_branch 
        FOREIGN KEY (branch_id) REFERENCES branches(id);
    END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);