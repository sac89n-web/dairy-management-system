#!/usr/bin/env python3
"""
Render Database Schema Deployment Script
This script deploys the complete dairy management schema to Render PostgreSQL
"""

import psycopg2
import os
import sys
from urllib.parse import urlparse

def parse_database_url(database_url):
    """Parse DATABASE_URL into connection parameters"""
    if not database_url:
        raise ValueError("DATABASE_URL environment variable is required")
    
    parsed = urlparse(database_url)
    
    return {
        'host': parsed.hostname,
        'port': parsed.port or 5432,
        'database': parsed.path[1:],  # Remove leading slash
        'user': parsed.username,
        'password': parsed.password
    }

def deploy_schema(database_url):
    """Deploy the complete schema to Render database"""
    
    print("🚀 Deploying Dairy Management Schema to Render...")
    print("=" * 50)
    
    try:
        # Parse connection parameters
        conn_params = parse_database_url(database_url)
        print(f"📡 Connecting to: {conn_params['host']}:{conn_params['port']}/{conn_params['database']}")
        
        # Connect to database
        conn = psycopg2.connect(
            host=conn_params['host'],
            port=conn_params['port'],
            database=conn_params['database'],
            user=conn_params['user'],
            password=conn_params['password'],
            sslmode='require'
        )
        
        print("✅ Connected to Render PostgreSQL")
        
        # Read schema file
        schema_file = 'complete_schema_sync.sql'
        if not os.path.exists(schema_file):
            print(f"❌ Schema file '{schema_file}' not found")
            return False
        
        with open(schema_file, 'r', encoding='utf-8') as f:
            schema_sql = f.read()
        
        print(f"📄 Loaded schema from {schema_file}")
        
        # Execute schema
        cursor = conn.cursor()
        cursor.execute(schema_sql)
        conn.commit()
        
        print("✅ Schema deployed successfully")
        
        # Verify deployment
        cursor.execute("""
            SELECT table_name, 
                   (SELECT COUNT(*) FROM information_schema.columns 
                    WHERE table_schema = 'dairy' AND table_name = t.table_name) as column_count
            FROM information_schema.tables t
            WHERE table_schema = 'dairy'
            ORDER BY table_name
        """)
        
        tables = cursor.fetchall()
        
        print(f"\n📊 Verification: {len(tables)} tables created")
        for table_name, column_count in tables:
            print(f"  ✓ {table_name} ({column_count} columns)")
        
        # Test basic functionality
        cursor.execute("SELECT COUNT(*) FROM dairy.users WHERE username = 'admin'")
        admin_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM dairy.branch")
        branch_count = cursor.fetchone()[0]
        
        print(f"\n🔍 Data verification:")
        print(f"  Admin users: {admin_count}")
        print(f"  Branches: {branch_count}")
        
        cursor.close()
        conn.close()
        
        print("\n🎉 Deployment completed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Deployment failed: {e}")
        return False

def main():
    """Main deployment function"""
    
    # Get DATABASE_URL from environment or command line
    database_url = os.environ.get('DATABASE_URL')
    
    if len(sys.argv) > 1:
        database_url = sys.argv[1]
    
    if not database_url:
        print("❌ DATABASE_URL is required")
        print("\nUsage:")
        print("  python deploy_render_schema.py [DATABASE_URL]")
        print("  or set DATABASE_URL environment variable")
        print("\nExample:")
        print("  python deploy_render_schema.py 'postgresql://user:pass@host:5432/dbname'")
        return False
    
    # Hide password in logs
    safe_url = database_url.replace(database_url.split('@')[0].split(':')[-1], '***')
    print(f"🔗 Using DATABASE_URL: {safe_url}")
    
    return deploy_schema(database_url)

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)