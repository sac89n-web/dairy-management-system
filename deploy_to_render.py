import psycopg2
import os
import sys

def deploy_schema_to_render():
    """Deploy feedback implementation schema to Render PostgreSQL"""
    
    # Render database connection (replace with your actual connection string)
    render_db_url = "postgresql://dairy_user:password@dpg-xyz-a.oregon-postgres.render.com/dairy_db"
    
    try:
        print("Connecting to Render PostgreSQL...")
        conn = psycopg2.connect(render_db_url)
        cur = conn.cursor()
        
        print("Applying feedback implementation schema...")
        
        # Read and execute the feedback schema
        with open('Scripts/feedback_implementation_schema.sql', 'r', encoding='utf-8') as f:
            schema_sql = f.read()
        
        cur.execute(schema_sql)
        conn.commit()
        
        print("✅ Schema deployed successfully to Render!")
        
        # Verify deployment
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'dairy' 
            AND table_name IN ('payment_cycles', 'bonus_configurations', 'system_alerts')
            ORDER BY table_name
        """)
        
        tables = cur.fetchall()
        print(f"📋 Verified tables: {[t[0] for t in tables]}")
        
        cur.close()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"❌ Error deploying to Render: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Deploying Dairy Management System to Render...")
    print("=" * 50)
    
    # Note: Replace the connection string above with your actual Render PostgreSQL URL
    print("⚠️  Please update the render_db_url variable with your actual Render database connection string")
    print("    You can find this in your Render dashboard under your PostgreSQL service")
    print("    Format: postgresql://username:password@host:port/database")
    
    # Uncomment the line below after updating the connection string
    # success = deploy_schema_to_render()
    
    print("\n📝 Manual deployment steps:")
    print("1. Copy the contents of 'Scripts/feedback_implementation_schema.sql'")
    print("2. Connect to your Render PostgreSQL using pgAdmin or psql")
    print("3. Execute the SQL script to create the new tables and features")
    print("4. Verify the deployment by checking the new tables exist")