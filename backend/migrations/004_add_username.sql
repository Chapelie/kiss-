-- Add username column to users table (without UNIQUE constraint first)
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50);

-- Update existing users to have a username based on email (if username is null)
-- This is a one-time migration for existing data
-- We need to ensure uniqueness by appending a number if needed
DO $$
DECLARE
    user_record RECORD;
    base_username VARCHAR(50);
    final_username VARCHAR(50);
    counter INTEGER;
BEGIN
    FOR user_record IN SELECT id, email FROM users WHERE username IS NULL LOOP
        base_username := LOWER(SPLIT_PART(user_record.email, '@', 1));
        final_username := base_username;
        counter := 1;
        
        -- Ensure uniqueness by appending a number if the username already exists
        WHILE EXISTS (SELECT 1 FROM users WHERE username = final_username AND id != user_record.id) LOOP
            final_username := base_username || counter::TEXT;
            counter := counter + 1;
        END LOOP;
        
        UPDATE users SET username = final_username WHERE id = user_record.id;
    END LOOP;
END $$;

-- Now add the UNIQUE constraint
-- First, drop the constraint if it exists (in case of previous failed migration)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_username_key;

-- Add the UNIQUE constraint
ALTER TABLE users ADD CONSTRAINT users_username_key UNIQUE (username);

-- Create index on username for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

