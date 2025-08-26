from db_context import DatabaseContext

def create_all_tables():
    db = DatabaseContext()
    
    with db.get_cursor() as cursor:
        # Create schema
        cursor.execute("CREATE SCHEMA IF NOT EXISTS dairy")
        cursor.execute("SET search_path TO dairy")
        
        # Create inventory tables
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS inventory_items (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                unit VARCHAR(20) NOT NULL DEFAULT 'Liters',
                min_stock DECIMAL(10,2) DEFAULT 0,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS inventory_transactions (
                id SERIAL PRIMARY KEY,
                item_id INT NOT NULL REFERENCES inventory_items(id),
                transaction_type VARCHAR(10) NOT NULL CHECK (transaction_type IN ('IN', 'OUT')),
                quantity DECIMAL(10,2) NOT NULL CHECK (quantity > 0),
                reference VARCHAR(255),
                transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        """)
        
        # Create routes tables
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS routes (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                driver_name VARCHAR(100) NOT NULL,
                vehicle_number VARCHAR(20) NOT NULL,
                status VARCHAR(20) DEFAULT 'Active',
                total_distance DECIMAL(8,2) DEFAULT 0,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS route_farmers (
                id SERIAL PRIMARY KEY,
                route_id INT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
                farmer_id INT NOT NULL REFERENCES farmer(id) ON DELETE CASCADE,
                sequence_order INT NOT NULL,
                UNIQUE(route_id, farmer_id)
            )
        """)
        
        # Create products table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS products (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                unit VARCHAR(20) DEFAULT 'Liters',
                price DECIMAL(8,2) NOT NULL,
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        """)
        
        # Create subscriptions tables
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS subscriptions (
                id SERIAL PRIMARY KEY,
                customer_id INT NOT NULL REFERENCES customer(id),
                product_id INT NOT NULL REFERENCES products(id),
                quantity DECIMAL(8,2) NOT NULL CHECK (quantity > 0),
                frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('Daily', 'Weekly', 'Monthly')),
                start_date DATE NOT NULL,
                next_delivery_date DATE NOT NULL,
                status VARCHAR(20) DEFAULT 'Active',
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS subscription_deliveries (
                id SERIAL PRIMARY KEY,
                subscription_id INT NOT NULL REFERENCES subscriptions(id),
                delivery_date DATE NOT NULL,
                delivered_quantity DECIMAL(8,2),
                status VARCHAR(20) DEFAULT 'Scheduled',
                notes TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        """)
        
        # Insert sample data
        cursor.execute("""
            INSERT INTO inventory_items (name, unit, min_stock) VALUES
            ('Milk', 'Liters', 100.0),
            ('Paneer', 'Kg', 10.0),
            ('Ghee', 'Kg', 5.0),
            ('Butter', 'Kg', 8.0),
            ('Curd', 'Liters', 50.0)
            ON CONFLICT DO NOTHING
        """)
        
        cursor.execute("""
            INSERT INTO inventory_transactions (item_id, transaction_type, quantity, reference) VALUES
            (1, 'IN', 500.0, 'Initial Stock'),
            (2, 'IN', 25.0, 'Production'),
            (3, 'IN', 15.0, 'Production')
            ON CONFLICT DO NOTHING
        """)
        
        cursor.execute("""
            INSERT INTO products (name, unit, price) VALUES
            ('Fresh Milk', 'Liters', 55.00),
            ('Toned Milk', 'Liters', 50.00),
            ('Full Cream Milk', 'Liters', 60.00),
            ('Paneer', 'Kg', 350.00),
            ('Curd', 'Liters', 45.00)
            ON CONFLICT DO NOTHING
        """)
        
        cursor.execute("""
            INSERT INTO routes (name, driver_name, vehicle_number, total_distance) VALUES
            ('Route A - North', 'Ramesh Kumar', 'MH12AB1234', 25.5),
            ('Route B - South', 'Suresh Patil', 'MH12CD5678', 18.2),
            ('Route C - East', 'Mahesh Singh', 'MH12EF9012', 32.1)
            ON CONFLICT DO NOTHING
        """)
        
        print("All tables created successfully with sample data!")

if __name__ == "__main__":
    try:
        create_all_tables()
    except Exception as e:
        print(f"Error: {e}")
        print("Make sure PostgreSQL is running and credentials are correct in db_context.py")