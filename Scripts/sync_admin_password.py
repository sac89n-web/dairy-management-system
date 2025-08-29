import psycopg2
import bcrypt
import os

def sync_admin_password():
    # Generate proper bcrypt hash for "admin123"
    password = "admin123"
    salt = bcrypt.gensalt()
    password_hash = bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
    
    # Render database connection (from environment or config)
    render_conn_string = os.getenv('DATABASE_URL') or "postgresql://postgres:TpXnyLAYfIJjZtsIcxNDWnICnwtUpDyC@turntable.proxy.rlwy.net:19238/railway"
    
    try:
        conn = psycopg2.connect(render_conn_string)
        cursor = conn.cursor()
        
        # Create schema and table if not exists
        cursor.execute("CREATE SCHEMA IF NOT EXISTS dairy")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS dairy.users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                role INTEGER DEFAULT 1,
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            )
        """)
        
        # Insert or update admin user
        cursor.execute("""
            INSERT INTO dairy.users (username, email, password_hash, role) VALUES
            (%s, %s, %s, %s)
            ON CONFLICT (username) 
            DO UPDATE SET 
                password_hash = %s,
                updated_at = NOW()
        """, ('admin', 'admin@dairy.com', password_hash, 1, password_hash))
        
        conn.commit()
        print("✓ Admin password synced successfully to Render database")
        print(f"Username: admin")
        print(f"Password: {password}")
        
    except Exception as e:
        print(f"Error syncing password: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    sync_admin_password()