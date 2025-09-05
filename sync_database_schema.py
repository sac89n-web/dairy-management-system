import psycopg2
import sys
from psycopg2.extras import RealDictCursor

# Local database connection
LOCAL_CONN = "Host=localhost;Database=postgres;Username=admin;Password=admin123;SearchPath=dairy"
# Convert to psycopg2 format
LOCAL_PG_CONN = "host=localhost dbname=postgres user=admin password=admin123 options='-c search_path=dairy'"

# Render database connection (update with your actual connection string)
RENDER_CONN = "postgresql://dairy_user:password@dpg-xyz-a.oregon-postgres.render.com/dairy_db"

def get_connection(conn_string):
    """Get database connection"""
    try:
        return psycopg2.connect(conn_string)
    except Exception as e:
        print(f"Connection failed: {e}")
        return None

def get_table_schema(conn, schema_name='dairy'):
    """Get all tables and their columns from a database"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # Get all tables in the schema
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = %s 
        ORDER BY table_name
    """, (schema_name,))
    
    tables = cursor.fetchall()
    schema_info = {}
    
    for table in tables:
        table_name = table['table_name']
        
        # Get columns for each table
        cursor.execute("""
            SELECT 
                column_name,
                data_type,
                is_nullable,
                column_default,
                character_maximum_length,
                numeric_precision,
                numeric_scale
            FROM information_schema.columns 
            WHERE table_schema = %s AND table_name = %s
            ORDER BY ordinal_position
        """, (schema_name, table_name))
        
        columns = cursor.fetchall()
        schema_info[table_name] = columns
    
    cursor.close()
    return schema_info

def compare_schemas(local_schema, render_schema):
    """Compare local and render schemas"""
    print("🔍 Schema Comparison Report")
    print("=" * 50)
    
    # Tables only in local
    local_only = set(local_schema.keys()) - set(render_schema.keys())
    if local_only:
        print(f"\n📋 Tables only in LOCAL: {local_only}")
    
    # Tables only in render
    render_only = set(render_schema.keys()) - set(local_schema.keys())
    if render_only:
        print(f"\n☁️ Tables only in RENDER: {render_only}")
    
    # Common tables
    common_tables = set(local_schema.keys()) & set(render_schema.keys())
    print(f"\n🤝 Common tables: {len(common_tables)}")
    
    # Compare columns in common tables
    for table in common_tables:
        local_cols = {col['column_name']: col for col in local_schema[table]}
        render_cols = {col['column_name']: col for col in render_schema[table]}
        
        local_only_cols = set(local_cols.keys()) - set(render_cols.keys())
        render_only_cols = set(render_cols.keys()) - set(local_cols.keys())
        
        if local_only_cols or render_only_cols:
            print(f"\n📊 Table: {table}")
            if local_only_cols:
                print(f"  📋 Columns only in LOCAL: {local_only_cols}")
            if render_only_cols:
                print(f"  ☁️ Columns only in RENDER: {render_only_cols}")

def generate_sync_sql(local_schema, render_schema):
    """Generate SQL to sync render with local schema"""
    sql_statements = []
    sql_statements.append("-- Database Schema Synchronization SQL")
    sql_statements.append("-- Run this on Render to match local schema")
    sql_statements.append("SET search_path TO dairy;")
    sql_statements.append("")
    
    # Tables only in local - create them on render
    local_only = set(local_schema.keys()) - set(render_schema.keys())
    for table in local_only:
        sql_statements.append(f"-- Create missing table: {table}")
        columns = local_schema[table]
        
        col_definitions = []
        for col in columns:
            col_def = f"{col['column_name']} {col['data_type']}"
            
            if col['character_maximum_length']:
                col_def = f"{col['column_name']} {col['data_type']}({col['character_maximum_length']})"
            elif col['numeric_precision']:
                if col['numeric_scale']:
                    col_def = f"{col['column_name']} {col['data_type']}({col['numeric_precision']},{col['numeric_scale']})"
                else:
                    col_def = f"{col['column_name']} {col['data_type']}({col['numeric_precision']})"
            
            if col['is_nullable'] == 'NO':
                col_def += " NOT NULL"
            
            if col['column_default']:
                col_def += f" DEFAULT {col['column_default']}"
                
            col_definitions.append(col_def)
        
        create_sql = f"CREATE TABLE IF NOT EXISTS {table} (\n    " + ",\n    ".join(col_definitions) + "\n);"
        sql_statements.append(create_sql)
        sql_statements.append("")
    
    # Common tables - add missing columns
    common_tables = set(local_schema.keys()) & set(render_schema.keys())
    for table in common_tables:
        local_cols = {col['column_name']: col for col in local_schema[table]}
        render_cols = {col['column_name']: col for col in render_schema[table]}
        
        missing_cols = set(local_cols.keys()) - set(render_cols.keys())
        if missing_cols:
            sql_statements.append(f"-- Add missing columns to table: {table}")
            for col_name in missing_cols:
                col = local_cols[col_name]
                col_def = f"{col['data_type']}"
                
                if col['character_maximum_length']:
                    col_def = f"{col['data_type']}({col['character_maximum_length']})"
                elif col['numeric_precision']:
                    if col['numeric_scale']:
                        col_def = f"{col['data_type']}({col['numeric_precision']},{col['numeric_scale']})"
                    else:
                        col_def = f"{col['data_type']}({col['numeric_precision']})"
                
                alter_sql = f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {col_name} {col_def}"
                
                if col['is_nullable'] == 'NO':
                    alter_sql += " NOT NULL"
                
                if col['column_default']:
                    alter_sql += f" DEFAULT {col['column_default']}"
                
                alter_sql += ";"
                sql_statements.append(alter_sql)
            sql_statements.append("")
    
    return "\n".join(sql_statements)

def main():
    print("🔄 Database Schema Synchronization Tool")
    print("=" * 40)
    
    # Connect to local database
    print("📋 Connecting to LOCAL database...")
    local_conn = get_connection(LOCAL_PG_CONN)
    if not local_conn:
        print("❌ Failed to connect to local database")
        return
    
    print("✅ Connected to local database")
    
    # Get local schema
    print("📊 Analyzing local schema...")
    local_schema = get_table_schema(local_conn)
    print(f"📋 Found {len(local_schema)} tables in local database")
    
    # For now, we'll create a mock render schema since we don't have the actual connection
    # In real scenario, you would connect to render database here
    print("\n⚠️ Note: Using mock render schema for demonstration")
    print("   Update RENDER_CONN with your actual Render database URL")
    
    render_schema = {
        'farmer': [
            {'column_name': 'id', 'data_type': 'integer', 'is_nullable': 'NO', 'column_default': 'nextval(\'farmer_id_seq\'::regclass)', 'character_maximum_length': None, 'numeric_precision': 32, 'numeric_scale': 0},
            {'column_name': 'name', 'data_type': 'character varying', 'is_nullable': 'NO', 'column_default': None, 'character_maximum_length': 100, 'numeric_precision': None, 'numeric_scale': None},
            {'column_name': 'code', 'data_type': 'character varying', 'is_nullable': 'NO', 'column_default': None, 'character_maximum_length': 20, 'numeric_precision': None, 'numeric_scale': None}
        ],
        'milk_collection': [
            {'column_name': 'id', 'data_type': 'integer', 'is_nullable': 'NO', 'column_default': 'nextval(\'milk_collection_id_seq\'::regclass)', 'character_maximum_length': None, 'numeric_precision': 32, 'numeric_scale': 0},
            {'column_name': 'farmer_id', 'data_type': 'integer', 'is_nullable': 'YES', 'column_default': None, 'character_maximum_length': None, 'numeric_precision': 32, 'numeric_scale': 0},
            {'column_name': 'date', 'data_type': 'date', 'is_nullable': 'NO', 'column_default': None, 'character_maximum_length': None, 'numeric_precision': None, 'numeric_scale': None}
        ]
    }
    
    # Compare schemas
    compare_schemas(local_schema, render_schema)
    
    # Generate sync SQL
    print("\n🔧 Generating synchronization SQL...")
    sync_sql = generate_sync_sql(local_schema, render_schema)
    
    # Save to file
    with open('render_sync.sql', 'w') as f:
        f.write(sync_sql)
    
    print("✅ Synchronization SQL saved to 'render_sync.sql'")
    print("\n📋 Local Database Tables:")
    for table_name, columns in local_schema.items():
        print(f"  📊 {table_name} ({len(columns)} columns)")
        for col in columns[:3]:  # Show first 3 columns
            print(f"    - {col['column_name']} ({col['data_type']})")
        if len(columns) > 3:
            print(f"    ... and {len(columns) - 3} more columns")
    
    local_conn.close()
    print("\n🎉 Schema analysis complete!")

if __name__ == "__main__":
    main()