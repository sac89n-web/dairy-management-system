import psycopg2
import sys

def verify_database():
    try:
        # Connection parameters
        conn = psycopg2.connect(
            host="localhost",
            port="5432",
            database="dairy",
            user="postgres",
            password="admin123"
        )
        
        cursor = conn.cursor()
        
        print("✓ Connected to PostgreSQL database 'dairy'")
        print("=" * 50)
        
        # Get all tables in dairy schema
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'dairy' 
            ORDER BY table_name
        """)
        
        tables = cursor.fetchall()
        
        print(f"\nFound {len(tables)} tables in 'dairy' schema:")
        for table in tables:
            print(f"  - {table[0]}")
        
        print("\n" + "=" * 50)
        
        # Verify each table structure
        for table in tables:
            table_name = table[0]
            print(f"\nTable: {table_name}")
            print("-" * 40)
            
            cursor.execute("""
                SELECT 
                    column_name,
                    data_type,
                    is_nullable,
                    column_default,
                    character_maximum_length
                FROM information_schema.columns 
                WHERE table_schema = 'dairy' AND table_name = %s
                ORDER BY ordinal_position
            """, (table_name,))
            
            columns = cursor.fetchall()
            
            for col in columns:
                col_name, data_type, is_nullable, col_default, max_length = col
                length_info = f"({max_length})" if max_length else ""
                null_info = "NULL" if is_nullable == "YES" else "NOT NULL"
                default_info = f" DEFAULT {col_default}" if col_default else ""
                
                print(f"  {col_name:<20} {data_type}{length_info:<15} {null_info}{default_info}")
        
        # Check sample data counts
        print("\n" + "=" * 50)
        print("Sample Data Counts:")
        print("-" * 20)
        
        for table in tables:
            table_name = table[0]
            cursor.execute(f"SELECT COUNT(*) FROM dairy.{table_name}")
            count = cursor.fetchone()[0]
            print(f"  {table_name:<25} {count} rows")
        
        cursor.close()
        conn.close()
        
    except psycopg2.Error as e:
        print(f"Database error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    verify_database()