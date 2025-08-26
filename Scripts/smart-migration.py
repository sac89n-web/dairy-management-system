import psycopg2
import sys

def migrate_schema():
    # Railway PostgreSQL connection
    railway_conn = psycopg2.connect(
        host="turntable.proxy.rlwy.net",
        port=19238,
        database="railway",
        user="postgres",
        password="TpXnyLAYfIJjZtsIcxNDWnICnwtUpDyC"
    )
    
    cursor = railway_conn.cursor()
    
    try:
        # Step 1: Create schema and tables without foreign keys
        cursor.execute("""
        CREATE SCHEMA IF NOT EXISTS dairy;
        SET search_path TO dairy, public;
        
        -- Drop existing tables if they exist
        DROP SCHEMA IF EXISTS dairy CASCADE;
        CREATE SCHEMA dairy;
        SET search_path TO dairy, public;
        
        -- Create all tables without foreign key constraints first
        CREATE TABLE dairy.bank (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL);
        CREATE TABLE dairy.branch (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, address TEXT, contact VARCHAR(50));
        CREATE TABLE dairy.employee (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, contact VARCHAR(50) NOT NULL, branch_id INTEGER, role VARCHAR(30) NOT NULL);
        CREATE TABLE dairy.user_account (id SERIAL PRIMARY KEY, login VARCHAR(50) UNIQUE NOT NULL, password_hash VARCHAR(255) NOT NULL, role VARCHAR(30) NOT NULL, person_ref INTEGER);
        CREATE TABLE dairy.farmer (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, code VARCHAR(20) UNIQUE NOT NULL, contact VARCHAR(50) NOT NULL, bank_id INTEGER, branch_id INTEGER, email VARCHAR(100), address TEXT, village VARCHAR(100), taluka VARCHAR(100), district VARCHAR(100), state VARCHAR(50) DEFAULT 'Maharashtra', pincode VARCHAR(10), bank_name VARCHAR(100), account_number VARCHAR(20), ifsc_code VARCHAR(15), aadhar_number VARCHAR(12), pan_number VARCHAR(10), is_active BOOLEAN DEFAULT true, created_at TIMESTAMP DEFAULT now(), updated_at TIMESTAMP DEFAULT now());
        CREATE TABLE dairy.customer (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, contact VARCHAR(50) NOT NULL, branch_id INTEGER, email VARCHAR(100), address TEXT, city VARCHAR(100), state VARCHAR(50) DEFAULT 'Maharashtra', pincode VARCHAR(10), gst_number VARCHAR(15), customer_type VARCHAR(50) DEFAULT 'Individual', is_active BOOLEAN DEFAULT true, created_at TIMESTAMP DEFAULT now(), updated_at TIMESTAMP DEFAULT now());
        CREATE TABLE dairy.shift (id SERIAL PRIMARY KEY, name VARCHAR(50) NOT NULL, start_time TIME, end_time TIME);
        CREATE TABLE dairy.milk_collection (id SERIAL PRIMARY KEY, farmer_id INTEGER, shift_id INTEGER, date DATE NOT NULL, qty_ltr DECIMAL(10,2) NOT NULL, fat_pct DECIMAL(10,2) NOT NULL, price_per_ltr DECIMAL(10,2) NOT NULL, due_amt DECIMAL(10,2) NOT NULL, notes TEXT, created_by INTEGER, snf_pct DECIMAL(10,2) DEFAULT 8.5, payment_status VARCHAR(20) DEFAULT 'Pending', payment_date TIMESTAMP, payment_reference VARCHAR(50));
        CREATE TABLE dairy.sales (id SERIAL PRIMARY KEY, customer_id INTEGER, shift_id INTEGER, date DATE NOT NULL, qty_ltr DECIMAL(10,2) NOT NULL, unit_price DECIMAL(10,2) NOT NULL, discount DECIMAL(10,2) DEFAULT 0, paid_amt DECIMAL(10,2) NOT NULL, due_amt DECIMAL(10,2) NOT NULL, created_by INTEGER);
        CREATE TABLE dairy.products (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, unit VARCHAR(20) DEFAULT 'Liters', price DECIMAL(10,2) NOT NULL, is_active BOOLEAN DEFAULT true, created_at TIMESTAMP DEFAULT now());
        CREATE TABLE dairy.invoices (id SERIAL PRIMARY KEY, invoice_number VARCHAR(30) UNIQUE NOT NULL, customer_id INTEGER, invoice_date DATE NOT NULL, subtotal DECIMAL(10,2) NOT NULL, tax_amount DECIMAL(10,2) DEFAULT 0, total_amount DECIMAL(10,2) NOT NULL, payment_method VARCHAR(20) NOT NULL, status VARCHAR(20) DEFAULT 'Pending', paid_date DATE, created_at TIMESTAMP DEFAULT now());
        CREATE TABLE dairy.invoice_items (id SERIAL PRIMARY KEY, invoice_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity DECIMAL(10,2) NOT NULL, unit_price DECIMAL(10,2) NOT NULL, total_price DECIMAL(10,2) NOT NULL);
        CREATE TABLE dairy.payment_transactions (id SERIAL PRIMARY KEY, payment_type VARCHAR(20) NOT NULL, farmer_id INTEGER, customer_id INTEGER, amount DECIMAL(10,2) NOT NULL, payment_method VARCHAR(20) NOT NULL, status VARCHAR(20) DEFAULT 'Pending', reference_id VARCHAR(50) UNIQUE NOT NULL, transaction_id VARCHAR(100), gateway_response TEXT, created_at TIMESTAMP DEFAULT now(), updated_at TIMESTAMP DEFAULT now());
        CREATE TABLE dairy.settings (id SERIAL PRIMARY KEY, system_name VARCHAR(100) NOT NULL, contact VARCHAR(50) NOT NULL, address TEXT NOT NULL);
        """)
        
        # Step 2: Insert basic data
        cursor.execute("""
        INSERT INTO dairy.bank (id, name) VALUES (1, 'State Bank of India'), (2, 'Bank of Maharashtra');
        INSERT INTO dairy.branch (id, name, address, contact) VALUES (1, 'Main Branch', '123 Dairy Lane', '9876543210');
        INSERT INTO dairy.employee (id, name, contact, branch_id, role) VALUES (1, 'Admin User', '9999999999', 1, 'Admin'), (2, 'Collector One', '8888888888', 1, 'CollectionBoy');
        INSERT INTO dairy.shift (id, name, start_time, end_time) VALUES (1, 'Morning', '06:00:00', '10:00:00'), (2, 'Evening', '16:00:00', '20:00:00');
        INSERT INTO dairy.settings (id, system_name, contact, address) VALUES (1, 'Dairy Management System', '9876543210', '123 Dairy Lane');
        INSERT INTO dairy.products (id, name, unit, price, is_active) VALUES (1, 'Fresh Milk', 'Liters', 55.00, true), (2, 'Toned Milk', 'Liters', 50.00, true), (11, 'Butter', 'Kg', 450.00, true);
        """)
        
        # Step 3: Insert farmers and customers
        cursor.execute("""
        INSERT INTO dairy.farmer (id, name, code, contact, bank_id, branch_id, village, taluka, district, state, is_active) VALUES 
        (1, 'Farmer A', 'F001', '7777777777', 1, 1, 'Village-1', 'Taluka-2', 'District-2', 'Maharashtra', true),
        (2, 'Farmer B', 'F002', '6666666666', 2, 1, 'Village-2', 'Taluka-3', 'District-3', 'Maharashtra', true),
        (3, 'Sachin Sawant', 'F124', '0000000000', NULL, 1, 'Village-3', 'Taluka-4', 'District-4', 'Maharashtra', true);
        
        INSERT INTO dairy.customer (id, name, contact, branch_id, city, state, customer_type, is_active) VALUES 
        (1, 'Customer X', '5555555555', 1, 'City-1', 'Maharashtra', 'Individual', true),
        (2, 'Customer Y', '4444444444', 1, 'City-2', 'Maharashtra', 'Individual', true),
        (3, 'Shravani Sawant', '0000000000', 1, 'City-3', 'Maharashtra', 'Individual', true);
        """)
        
        # Step 4: Insert invoices first, then invoice items
        cursor.execute("""
        INSERT INTO dairy.invoices (id, invoice_number, customer_id, invoice_date, subtotal, tax_amount, total_amount, payment_method, status) VALUES 
        (1, 'INV20250820135717', 3, '2025-08-20', 1.00, 0.18, 1.18, 'Cash', 'Paid'),
        (2, 'INV20250826194922', 3, '2025-08-26', 4800.00, 864.00, 5664.00, 'Cash', 'Paid');
        
        INSERT INTO dairy.invoice_items (id, invoice_id, product_id, quantity, unit_price, total_price) VALUES 
        (1, 1, 11, 1.00, 1.00, 1.00),
        (2, 2, 11, 12.00, 400.00, 4800.00);
        """)
        
        # Step 5: Insert milk collections and sales
        cursor.execute("""
        INSERT INTO dairy.milk_collection (id, farmer_id, shift_id, date, qty_ltr, fat_pct, price_per_ltr, due_amt, snf_pct, payment_status) VALUES 
        (2, 3, 1, '2025-08-19', 100.00, 14.00, 90.00, 9000.00, 8.50, 'Paid'),
        (3, 1, 1, '2025-08-19', 78.00, 10.00, 99.00, 7722.00, 8.50, 'Pending'),
        (7, 1, 1, '2025-08-20', 40.00, 2.90, 109.00, 4360.00, 8.50, 'Pending');
        
        INSERT INTO dairy.sales (id, customer_id, shift_id, date, qty_ltr, unit_price, discount, paid_amt, due_amt) VALUES 
        (1, 1, 1, '2025-08-20', 50.00, 55.00, 0.00, 2750.00, 0.00),
        (2, 2, 1, '2025-08-20', 30.00, 50.00, 0.00, 1500.00, 0.00);
        """)
        
        # Step 6: Add foreign key constraints
        cursor.execute("""
        ALTER TABLE dairy.employee ADD CONSTRAINT employee_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES dairy.branch(id);
        ALTER TABLE dairy.farmer ADD CONSTRAINT farmer_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES dairy.branch(id);
        ALTER TABLE dairy.farmer ADD CONSTRAINT fk_farmer_bank FOREIGN KEY (bank_id) REFERENCES dairy.bank(id);
        ALTER TABLE dairy.customer ADD CONSTRAINT customer_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES dairy.branch(id);
        ALTER TABLE dairy.milk_collection ADD CONSTRAINT milk_collection_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES dairy.farmer(id);
        ALTER TABLE dairy.milk_collection ADD CONSTRAINT milk_collection_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES dairy.shift(id);
        ALTER TABLE dairy.sales ADD CONSTRAINT sale_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES dairy.customer(id);
        ALTER TABLE dairy.sales ADD CONSTRAINT sale_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES dairy.shift(id);
        ALTER TABLE dairy.invoices ADD CONSTRAINT invoices_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES dairy.customer(id);
        ALTER TABLE dairy.invoice_items ADD CONSTRAINT invoice_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES dairy.invoices(id);
        ALTER TABLE dairy.invoice_items ADD CONSTRAINT invoice_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES dairy.products(id);
        """)
        
        # Step 7: Create indexes
        cursor.execute("""
        CREATE INDEX idx_milk_collection_farmer_date ON dairy.milk_collection(farmer_id, date);
        CREATE INDEX idx_sales_customer_date ON dairy.sales(customer_id, date);
        CREATE INDEX idx_farmer_code ON dairy.farmer(code);
        CREATE INDEX idx_customer_contact ON dairy.customer(contact);
        """)
        
        # Step 8: Grant permissions
        cursor.execute("""
        GRANT ALL PRIVILEGES ON SCHEMA dairy TO PUBLIC;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dairy TO PUBLIC;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dairy TO PUBLIC;
        """)
        
        railway_conn.commit()
        print("Smart migration completed successfully!")
        return True
        
    except Exception as e:
        railway_conn.rollback()
        print(f"Error during migration: {e}")
        return False
        
    finally:
        cursor.close()
        railway_conn.close()

if __name__ == "__main__":
    success = migrate_schema()
    sys.exit(0 if success else 1)