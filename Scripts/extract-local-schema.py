import psycopg2
import sys

def extract_schema():
    # Local PostgreSQL connection
    local_conn = psycopg2.connect(
        host="localhost",
        database="postgres", 
        user="admin",
        password="admin123"
    )
    
    cursor = local_conn.cursor()
    
    # Get all tables in dairy schema
    cursor.execute("""
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'dairy' 
        ORDER BY table_name
    """)
    tables = [row[0] for row in cursor.fetchall()]
    
    script_lines = [
        "-- Generated schema from local PostgreSQL",
        "-- Run this on Railway PostgreSQL",
        "",
        "CREATE SCHEMA IF NOT EXISTS dairy;",
        "SET search_path TO dairy, public;",
        ""
    ]
    
    # Extract table definitions
    for table in tables:
        cursor.execute(f"""
            SELECT column_name, data_type, character_maximum_length, 
                   is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_schema = 'dairy' AND table_name = '{table}'
            ORDER BY ordinal_position
        """)
        
        columns = cursor.fetchall()
        script_lines.append(f"-- Table: {table}")
        script_lines.append(f"CREATE TABLE IF NOT EXISTS dairy.{table} (")
        
        col_definitions = []
        for col in columns:
            col_name, data_type, max_length, nullable, default = col
            
            # Build column definition
            col_def = f"    {col_name} "
            
            if data_type == 'character varying':
                col_def += f"VARCHAR({max_length or 255})"
            elif data_type == 'integer':
                col_def += "INTEGER"
            elif data_type == 'numeric':
                col_def += "DECIMAL(10,2)"
            elif data_type == 'boolean':
                col_def += "BOOLEAN"
            elif data_type == 'date':
                col_def += "DATE"
            elif data_type == 'time without time zone':
                col_def += "TIME"
            elif data_type == 'timestamp without time zone':
                col_def += "TIMESTAMP"
            elif data_type == 'text':
                col_def += "TEXT"
            elif data_type == 'jsonb':
                col_def += "JSONB"
            else:
                col_def += data_type.upper()
            
            if nullable == 'NO':
                col_def += " NOT NULL"
            
            if default:
                if 'nextval' in default:
                    col_def = col_def.replace('INTEGER', 'SERIAL PRIMARY KEY')
                elif default not in ['CURRENT_DATE', 'CURRENT_TIME', 'CURRENT_TIMESTAMP']:
                    col_def += f" DEFAULT {default}"
                else:
                    col_def += f" DEFAULT {default}"
            
            col_definitions.append(col_def)
        
        script_lines.append(",\n".join(col_definitions))
        script_lines.append(");")
        script_lines.append("")
    
    # Extract indexes
    cursor.execute("""
        SELECT indexname, tablename, indexdef 
        FROM pg_indexes 
        WHERE schemaname = 'dairy' AND indexname NOT LIKE '%_pkey'
    """)
    
    indexes = cursor.fetchall()
    if indexes:
        script_lines.append("-- Indexes")
        for idx_name, table_name, idx_def in indexes:
            script_lines.append(f"{idx_def};")
        script_lines.append("")
    
    # Extract foreign keys
    cursor.execute("""
        SELECT tc.constraint_name, tc.table_name, kcu.column_name,
               ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'dairy'
    """)
    
    foreign_keys = cursor.fetchall()
    if foreign_keys:
        script_lines.append("-- Foreign Keys")
        for fk_name, table_name, column_name, ref_table, ref_column in foreign_keys:
            script_lines.append(f"ALTER TABLE dairy.{table_name} ADD CONSTRAINT {fk_name} FOREIGN KEY ({column_name}) REFERENCES dairy.{ref_table}({ref_column});")
        script_lines.append("")
    
    # Extract data
    script_lines.append("-- Data")
    for table in tables:
        cursor.execute(f"SELECT * FROM dairy.{table}")
        rows = cursor.fetchall()
        
        if rows:
            cursor.execute(f"""
                SELECT column_name FROM information_schema.columns 
                WHERE table_schema = 'dairy' AND table_name = '{table}'
                ORDER BY ordinal_position
            """)
            columns = [row[0] for row in cursor.fetchall()]
            
            for row in rows:
                values = []
                for val in row:
                    if val is None:
                        values.append('NULL')
                    elif isinstance(val, str):
                        values.append(f"'{val.replace("'", "''")}'")
                    elif hasattr(val, 'isoformat'):  # datetime objects
                        values.append(f"'{val.isoformat()}'")
                    elif isinstance(val, bool):
                        values.append('TRUE' if val else 'FALSE')
                    else:
                        values.append(str(val))
                
                script_lines.append(f"INSERT INTO dairy.{table} ({', '.join(columns)}) VALUES ({', '.join(values)}) ON CONFLICT DO NOTHING;")
    
    script_lines.extend([
        "",
        "-- Permissions",
        "GRANT ALL PRIVILEGES ON SCHEMA dairy TO PUBLIC;",
        "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dairy TO PUBLIC;",
        "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dairy TO PUBLIC;",
        "",
        "SELECT 'Schema migration completed successfully!' as status;"
    ])
    
    cursor.close()
    local_conn.close()
    
    return "\n".join(script_lines)

if __name__ == "__main__":
    try:
        schema_script = extract_schema()
        
        # Write to file
        with open("Scripts/local-to-railway-migration.sql", "w", encoding="utf-8") as f:
            f.write(schema_script)
        
        print("Schema extracted successfully to Scripts/local-to-railway-migration.sql")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)