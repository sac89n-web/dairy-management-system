import psycopg2

def verify_migration():
    conn = psycopg2.connect(
        host="turntable.proxy.rlwy.net",
        port=19238,
        database="railway",
        user="postgres",
        password="TpXnyLAYfIJjZtsIcxNDWnICnwtUpDyC"
    )
    
    cursor = conn.cursor()
    
    # Check tables
    cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'dairy' ORDER BY table_name")
    tables = [row[0] for row in cursor.fetchall()]
    print(f"Tables created: {len(tables)}")
    for table in tables:
        print(f"  - {table}")
    
    # Check data counts
    print("\nData counts:")
    for table in tables:
        cursor.execute(f"SELECT COUNT(*) FROM dairy.{table}")
        count = cursor.fetchone()[0]
        print(f"  {table}: {count} records")
    
    cursor.close()
    conn.close()

if __name__ == "__main__":
    verify_migration()