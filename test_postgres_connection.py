import psycopg2

# Connection parameters
conn_params = {
    'host': 'localhost',
    'database': 'postgres',
    'user': 'admin',
    'password': 'admin123'
}

try:
    conn = psycopg2.connect(**conn_params)
    print('Connection successful!')
    conn.close()
except Exception as e:
    print('Connection failed:', e)
