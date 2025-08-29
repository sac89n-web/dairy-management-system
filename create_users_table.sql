-- Create the missing users table in dairy schema
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

-- Insert a default admin user (role 1 = Admin, 2 = User)
INSERT INTO dairy.users (username, email, password_hash, role) VALUES
('admin', 'admin@dairy.com', '$2a$11$dummy.hash.for.admin.user', 1)
ON CONFLICT (username) DO NOTHING;

-- Create other essential tables if they don't exist
CREATE TABLE IF NOT EXISTS dairy.farmer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dairy.customer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dairy.milk_collection (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES dairy.farmer(id),
    collection_date DATE DEFAULT CURRENT_DATE,
    quantity DECIMAL(8,2) NOT NULL,
    fat_pct DECIMAL(5,2) DEFAULT 0,
    rate DECIMAL(8,2) DEFAULT 0,
    amount DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dairy.sales (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES dairy.customer(id),
    sale_date DATE DEFAULT CURRENT_DATE,
    quantity DECIMAL(8,2) NOT NULL,
    rate DECIMAL(8,2) DEFAULT 0,
    amount DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample data
INSERT INTO dairy.farmer (name, phone, address) VALUES
('राम पाटील', '9876543210', 'गाव: शिरपूर, तालुका: शिरपूर'),
('श्याम जाधव', '9876543211', 'गाव: धुळे, तालुका: धुळे')
ON CONFLICT DO NOTHING;

INSERT INTO dairy.customer (name, phone, address) VALUES
('सुनील शर्मा', '9876543220', 'नाशिक रोड, नाशिक'),
('अनिल कुमार', '9876543221', 'कॉलेज रोड, नाशिक')
ON CONFLICT DO NOTHING;