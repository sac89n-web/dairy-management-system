import psycopg2
import os

def apply_feedback_schema():
    try:
        # Database connection
        conn = psycopg2.connect(
            host="localhost",
            database="postgres",
            user="admin",
            password="admin123"
        )
        
        cur = conn.cursor()
        
        # Read and execute the feedback schema
        with open('Scripts/feedback_implementation_schema.sql', 'r', encoding='utf-8') as f:
            schema_sql = f.read()
        
        cur.execute(schema_sql)
        conn.commit()
        
        print("✅ Feedback implementation schema applied successfully!")
        
        # Verify tables created
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'dairy' 
            AND table_name IN ('payment_cycles', 'bonus_configurations', 'notification_preferences', 'system_alerts')
            ORDER BY table_name
        """)
        
        tables = cur.fetchall()
        print(f"📋 New tables created: {[t[0] for t in tables]}")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    apply_feedback_schema()