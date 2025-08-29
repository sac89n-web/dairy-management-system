-- Update admin password in dairy.users table
-- This represents the local database changes made manually
UPDATE dairy.users 
SET password_hash = '$2a$11$updated.hash.for.admin.password.change'
WHERE username = 'admin';