-- Check Local Database Schema
-- Run this against your local PostgreSQL database

SET search_path TO dairy;

-- Check if dairy schema exists
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'dairy';

-- List all tables in dairy schema
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'dairy' 
ORDER BY table_name;

-- Get detailed column information for all tables
SELECT 
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default,
    CASE 
        WHEN c.character_maximum_length IS NOT NULL THEN c.data_type || '(' || c.character_maximum_length || ')'
        WHEN c.numeric_precision IS NOT NULL AND c.numeric_scale IS NOT NULL THEN c.data_type || '(' || c.numeric_precision || ',' || c.numeric_scale || ')'
        WHEN c.numeric_precision IS NOT NULL THEN c.data_type || '(' || c.numeric_precision || ')'
        ELSE c.data_type
    END as full_data_type
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name AND t.table_schema = c.table_schema
WHERE t.table_schema = 'dairy'
ORDER BY t.table_name, c.ordinal_position;

-- Check for foreign key constraints
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'dairy'
ORDER BY tc.table_name, kcu.column_name;

-- Check for indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'dairy'
ORDER BY tablename, indexname;