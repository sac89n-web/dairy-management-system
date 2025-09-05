-- Database Schema Verification Script for Dairy Management System
-- Run this in your PostgreSQL client (pgAdmin, psql, etc.)

\echo '=== DAIRY SCHEMA VERIFICATION ==='
\echo ''

-- Check if dairy schema exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'dairy') 
        THEN '✓ Dairy schema exists'
        ELSE '✗ Dairy schema NOT found'
    END as schema_status;

\echo ''
\echo '=== TABLES IN DAIRY SCHEMA ==='

-- List all tables in dairy schema
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'dairy' 
ORDER BY table_name;

\echo ''
\echo '=== TABLE STRUCTURES ==='

-- Get detailed structure for each table
DO $$
DECLARE
    tbl_name text;
    col_info record;
BEGIN
    FOR tbl_name IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'dairy' 
        ORDER BY table_name
    LOOP
        RAISE NOTICE '';
        RAISE NOTICE 'Table: %', tbl_name;
        RAISE NOTICE '%', repeat('-', 50);
        
        FOR col_info IN
            SELECT 
                column_name,
                data_type,
                CASE 
                    WHEN character_maximum_length IS NOT NULL 
                    THEN data_type || '(' || character_maximum_length || ')'
                    WHEN numeric_precision IS NOT NULL AND numeric_scale IS NOT NULL
                    THEN data_type || '(' || numeric_precision || ',' || numeric_scale || ')'
                    ELSE data_type
                END as full_type,
                is_nullable,
                column_default
            FROM information_schema.columns 
            WHERE table_schema = 'dairy' AND table_name = tbl_name
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  %-20s %-20s %-8s %s', 
                col_info.column_name, 
                col_info.full_type,
                CASE WHEN col_info.is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END,
                COALESCE('DEFAULT ' || col_info.column_default, '');
        END LOOP;
    END LOOP;
END $$;

\echo ''
\echo '=== FOREIGN KEY CONSTRAINTS ==='

SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'dairy'
ORDER BY tc.table_name, kcu.column_name;

\echo ''
\echo '=== INDEXES ==='

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'dairy'
ORDER BY tablename, indexname;

\echo ''
\echo '=== DATA COUNTS ==='

-- Count records in each table
DO $$
DECLARE
    tbl_name text;
    row_count integer;
BEGIN
    FOR tbl_name IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'dairy' 
        ORDER BY table_name
    LOOP
        EXECUTE 'SELECT COUNT(*) FROM dairy.' || quote_ident(tbl_name) INTO row_count;
        RAISE NOTICE '%-25s %s rows', tbl_name, row_count;
    END LOOP;
END $$;

\echo ''
\echo '=== VERIFICATION COMPLETE ==='