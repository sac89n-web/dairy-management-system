-- Additional tables for web application compatibility
SET search_path TO dairy;

-- Create simplified tables that match the application model
CREATE TABLE IF NOT EXISTS milk_collections (
    id SERIAL PRIMARY KEY,
    farmer_name VARCHAR(100) NOT NULL,
    quantity NUMERIC(8,2) NOT NULL,
    fat_percentage NUMERIC(4,2) NOT NULL,
    rate_per_liter NUMERIC(8,2) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    collection_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sales (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    quantity NUMERIC(8,2) NOT NULL,
    rate_per_liter NUMERIC(8,2) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO milk_collections (farmer_name, quantity, fat_percentage, rate_per_liter, total_amount, collection_date) VALUES
('Farmer A', 25.5, 4.2, 50.00, 1275.00, CURRENT_DATE - INTERVAL '1 day'),
('Farmer B', 18.0, 3.8, 50.00, 900.00, CURRENT_DATE - INTERVAL '1 day'),
('Farmer A', 30.0, 4.5, 52.00, 1560.00, CURRENT_DATE),
('Farmer C', 22.5, 4.0, 51.00, 1147.50, CURRENT_DATE);

INSERT INTO sales (customer_name, quantity, rate_per_liter, total_amount, sale_date) VALUES
('Customer X', 15.0, 55.00, 825.00, CURRENT_DATE - INTERVAL '1 day'),
('Customer Y', 20.0, 55.00, 1100.00, CURRENT_DATE - INTERVAL '1 day'),
('Customer X', 12.0, 56.00, 672.00, CURRENT_DATE),
('Customer Z', 25.0, 55.00, 1375.00, CURRENT_DATE);