import psycopg2
import sys

def test_connection_and_apply_schema():
    try:
        # Connect using provided credentials
        conn = psycopg2.connect(
            host="localhost",
            database="postgres", 
            user="admin",
            password="admin123"
        )
        
        cur = conn.cursor()
        
        # Set search path
        cur.execute("SET search_path TO dairy;")
        
        print("Connected to PostgreSQL successfully!")
        
        # Read feedback schema file
        with open('Scripts/feedback_implementation_schema.sql', 'r', encoding='utf-8') as f:
            schema_sql = f.read()
        
        # Execute schema
        cur.execute(schema_sql)
        conn.commit()
        
        print("Feedback implementation schema applied successfully!")
        
        # Verify new tables
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'dairy' 
            AND table_name LIKE '%payment%' OR table_name LIKE '%bonus%' OR table_name LIKE '%notification%'
            ORDER BY table_name
        """)
        
        tables = cur.fetchall()
        print(f"New tables: {[t[0] for t in tables]}")
        
        cur.close()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    success = test_connection_and_apply_schema()
    sys.exit(0 if success else 1)