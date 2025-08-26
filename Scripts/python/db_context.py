import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager

class DatabaseContext:
    def __init__(self):
        self.connection_string = {
            'host': 'localhost',
            'port': 5432,
            'database': 'postgres',
            'user': 'postgres',
            'password': 'admin123'
        }
    
    @contextmanager
    def get_connection(self):
        conn = None
        try:
            conn = psycopg2.connect(**self.connection_string)
            yield conn
        except Exception as e:
            if conn:
                conn.rollback()
            raise e
        finally:
            if conn:
                conn.close()
    
    @contextmanager
    def get_cursor(self, dict_cursor=True):
        with self.get_connection() as conn:
            cursor_factory = RealDictCursor if dict_cursor else None
            cursor = conn.cursor(cursor_factory=cursor_factory)
            try:
                yield cursor
                conn.commit()
            except Exception as e:
                conn.rollback()
                raise e
            finally:
                cursor.close()

# Usage example
if __name__ == "__main__":
    db = DatabaseContext()
    
    # Create tables
    with db.get_cursor() as cursor:
        cursor.execute("""
            CREATE SCHEMA IF NOT EXISTS dairy;
            SET search_path TO dairy;
            
            CREATE TABLE IF NOT EXISTS inventory_items (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                unit VARCHAR(20) DEFAULT 'Liters',
                min_stock DECIMAL(10,2) DEFAULT 0
            );
        """)
        print("Tables created successfully")
    
    # Insert data
    with db.get_cursor() as cursor:
        cursor.execute("""
            INSERT INTO dairy.inventory_items (name, unit, min_stock) 
            VALUES (%s, %s, %s) ON CONFLICT DO NOTHING
        """, ('Milk', 'Liters', 100.0))
        print("Data inserted successfully")
    
    # Query data
    with db.get_cursor() as cursor:
        cursor.execute("SELECT * FROM dairy.inventory_items")
        results = cursor.fetchall()
        for row in results:
            print(f"ID: {row['id']}, Name: {row['name']}, Stock: {row['min_stock']}")