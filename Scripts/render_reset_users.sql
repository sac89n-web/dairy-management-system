-- Drop and recreate users table on Render with admin123 password
-- Run this on Render PostgreSQL console

DROP TABLE IF EXISTS dairy.users CASCADE;

CREATE TABLE dairy.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO dairy.users (username, email, password_hash, role) VALUES
('admin', 'admin@dairy.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj3bp.gSInG2', 1);