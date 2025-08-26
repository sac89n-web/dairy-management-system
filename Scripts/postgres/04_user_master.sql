-- User Master Table
CREATE TABLE IF NOT EXISTS user_master (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'User',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- OTP Table
CREATE TABLE IF NOT EXISTS user_otp (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin user
INSERT INTO user_master (mobile, name, role) 
VALUES ('8108891477', 'Admin', 'Admin')
ON CONFLICT (mobile) DO NOTHING;