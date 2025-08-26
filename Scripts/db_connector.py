#!/usr/bin/env python3
import psycopg2
import sys
import json

def test_connection(host, database, username, password, port=5432):
    """Test PostgreSQL connection and return result as JSON"""
    try:
        conn = psycopg2.connect(
            host=host,
            database=database,
            user=username,
            password=password,
            port=port,
            connect_timeout=10
        )
        
        # Test basic query
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        
        cursor.close()
        conn.close()
        
        return {
            "success": True,
            "message": "Connection successful",
            "version": version
        }
        
    except psycopg2.OperationalError as e:
        return {
            "success": False,
            "error": "Connection failed",
            "details": str(e)
        }
    except Exception as e:
        return {
            "success": False,
            "error": "Unexpected error",
            "details": str(e)
        }

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print(json.dumps({
            "success": False,
            "error": "Usage: python db_connector.py <host> <database> <username> <password>"
        }))
        sys.exit(1)
    
    host = sys.argv[1]
    database = sys.argv[2]
    username = sys.argv[3]
    password = sys.argv[4]
    
    result = test_connection(host, database, username, password)
    print(json.dumps(result))