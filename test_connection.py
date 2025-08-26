import psycopg2
import sys

try:
    # Test connection with your credentials
    conn = psycopg2.connect(
        host="localhost",
        database="postgres",
        user="admin",
        password="admin123",
        port=5432
    )
    
    cursor = conn.cursor()
    cursor.execute("SELECT version();")
    version = cursor.fetchone()[0]
    
    # Test dairy schema access
    cursor.execute("SET search_path TO dairy;")
    cursor.execute("SELECT current_schema();")
    schema = cursor.fetchone()[0]
    
    cursor.close()
    conn.close()
    
    print("SUCCESS: Connected to PostgreSQL")
    print(f"Version: {version}")
    print(f"Schema: {schema}")
    
except Exception as e:
    print(f"FAILED: {e}")
    sys.exit(1)