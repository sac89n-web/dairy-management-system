-- Route Management Schema
SET search_path TO dairy;

-- Routes
CREATE TABLE IF NOT EXISTS routes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    driver_name VARCHAR(100) NOT NULL,
    vehicle_number VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'In Progress', 'Completed', 'Inactive')),
    total_distance DECIMAL(8,2) DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Route Farmers (Many-to-Many)
CREATE TABLE IF NOT EXISTS route_farmers (
    id SERIAL PRIMARY KEY,
    route_id INT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    farmer_id INT NOT NULL REFERENCES farmer(id) ON DELETE CASCADE,
    sequence_order INT NOT NULL,
    estimated_time TIME,
    UNIQUE(route_id, farmer_id)
);

-- Route Tracking (GPS coordinates)
CREATE TABLE IF NOT EXISTS route_tracking (
    id SERIAL PRIMARY KEY,
    route_id INT NOT NULL REFERENCES routes(id),
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    speed DECIMAL(5,2),
    status VARCHAR(50)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_route_farmers_route ON route_farmers(route_id);
CREATE INDEX IF NOT EXISTS idx_route_tracking_route_time ON route_tracking(route_id, timestamp);

-- Sample Data
INSERT INTO routes (name, driver_name, vehicle_number, total_distance) VALUES
('Route A - North', 'Ramesh Kumar', 'MH12AB1234', 25.5),
('Route B - South', 'Suresh Patil', 'MH12CD5678', 18.2),
('Route C - East', 'Mahesh Singh', 'MH12EF9012', 32.1)
ON CONFLICT DO NOTHING;

-- Assign farmers to routes
INSERT INTO route_farmers (route_id, farmer_id, sequence_order) VALUES
(1, 1, 1),
(1, 2, 2),
(2, 1, 1)
ON CONFLICT DO NOTHING;