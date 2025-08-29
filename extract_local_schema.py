import psycopg2

# Connect to local PostgreSQL
conn = psycopg2.connect(
    host="localhost",
    database="postgres",
    user="admin",
    password="admin123"
)

cur = conn.cursor()

# Get all tables in dairy schema
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'dairy' 
    ORDER BY table_name
""")
tables = [row[0] for row in cur.fetchall()]

print("-- Local PostgreSQL Schema Export")
print("-- Tables found:", len(tables))
print("-- Tables:", ", ".join(tables))
print()

# Generate complete schema
schema_sql = "CREATE SCHEMA IF NOT EXISTS dairy;\nSET search_path TO dairy;\n\n"

for table in tables:
    # Get table structure
    cur.execute(f"""
        SELECT column_name, data_type, character_maximum_length, 
               is_nullable, column_default, numeric_precision, numeric_scale
        FROM information_schema.columns 
        WHERE table_schema = 'dairy' AND table_name = '{table}'
        ORDER BY ordinal_position
    """)
    
    columns = cur.fetchall()
    
    schema_sql += f"CREATE TABLE IF NOT EXISTS {table} (\n"
    col_defs = []
    
    for col in columns:
        col_name, data_type, max_len, nullable, default, precision, scale = col
        
        col_def = f"    {col_name} "
        
        if data_type == 'integer' and default and 'nextval' in str(default):
            col_def += "SERIAL PRIMARY KEY"
        elif data_type == 'integer':
            col_def += "INTEGER"
        elif data_type == 'character varying':
            col_def += f"VARCHAR({max_len})" if max_len else "VARCHAR(255)"
        elif data_type == 'text':
            col_def += "TEXT"
        elif data_type == 'numeric':
            if precision and scale:
                col_def += f"NUMERIC({precision},{scale})"
            else:
                col_def += "NUMERIC(12,2)"
        elif data_type == 'date':
            col_def += "DATE"
        elif data_type == 'timestamp without time zone':
            col_def += "TIMESTAMP"
        elif data_type == 'time without time zone':
            col_def += "TIME"
        else:
            col_def += data_type.upper()
        
        if nullable == 'NO' and not ('SERIAL' in col_def):
            col_def += " NOT NULL"
        
        if default and not ('nextval' in str(default)) and not ('SERIAL' in col_def):
            if 'CURRENT_TIMESTAMP' in str(default):
                col_def += " DEFAULT CURRENT_TIMESTAMP"
            elif str(default).replace("'", "").isdigit():
                col_def += f" DEFAULT {default}"
            
        col_defs.append(col_def)
    
    schema_sql += ",\n".join(col_defs)
    schema_sql += "\n);\n\n"

# Get indexes
cur.execute("""
    SELECT indexname, indexdef 
    FROM pg_indexes 
    WHERE schemaname = 'dairy' AND indexname NOT LIKE '%_pkey'
    ORDER BY indexname
""")
indexes = cur.fetchall()

for idx_name, idx_def in indexes:
    schema_sql += idx_def + ";\n"

if indexes:
    schema_sql += "\n"

# Get constraints
cur.execute("""
    SELECT conname, pg_get_constraintdef(oid) as definition
    FROM pg_constraint 
    WHERE connamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'dairy')
    AND contype = 'f'
    ORDER BY conname
""")
constraints = cur.fetchall()

for constraint_name, constraint_def in constraints:
    schema_sql += f"-- {constraint_name}: {constraint_def}\n"

cur.close()
conn.close()

# Write to file
with open('local_complete_schema.sql', 'w') as f:
    f.write(schema_sql)

print(f"Schema exported to local_complete_schema.sql")
print(f"Found {len(tables)} tables and {len(indexes)} indexes")