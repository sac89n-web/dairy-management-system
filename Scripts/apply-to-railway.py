import psycopg2
import sys
import os

def apply_to_railway():
    # Railway PostgreSQL connection
    railway_conn = psycopg2.connect(
        host="turntable.proxy.rlwy.net",
        port=19238,
        database="railway",
        user="postgres",
        password="TpXnyLAYfIJjZtsIcxNDWnICnwtUpDyC"
    )
    
    # Read the migration script
    script_path = "Scripts/local-to-railway-migration.sql"
    if not os.path.exists(script_path):
        print("Migration script not found. Run extract-local-schema.py first.")
        return False
    
    with open(script_path, "r", encoding="utf-8") as f:
        sql_script = f.read()
    
    cursor = railway_conn.cursor()
    
    try:
        # Execute the script
        cursor.execute(sql_script)
        railway_conn.commit()
        print("Schema applied to Railway PostgreSQL successfully!")
        return True
        
    except Exception as e:
        railway_conn.rollback()
        print(f"Error applying schema: {e}")
        return False
        
    finally:
        cursor.close()
        railway_conn.close()

if __name__ == "__main__":
    success = apply_to_railway()
    sys.exit(0 if success else 1)