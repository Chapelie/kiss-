-- Script de correction pour la contrainte username
-- À exécuter manuellement si la migration 004 échoue
-- Ce fichier n'est PAS une migration, c'est un script de correction manuel

-- 1. Supprimer la contrainte UNIQUE si elle existe (en cas d'échec partiel)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_username_key;

-- 2. Supprimer l'index s'il existe
DROP INDEX IF EXISTS idx_users_username;

-- 3. Mettre à jour tous les usernames NULL ou vides avec des valeurs uniques
DO $$
DECLARE
    user_record RECORD;
    base_username VARCHAR(50);
    final_username VARCHAR(50);
    counter INTEGER;
BEGIN
    FOR user_record IN SELECT id, email FROM users WHERE username IS NULL OR username = '' LOOP
        base_username := LOWER(SPLIT_PART(user_record.email, '@', 1));
        final_username := base_username;
        counter := 1;
        
        -- S'assurer de l'unicité en ajoutant un numéro si nécessaire
        WHILE EXISTS (SELECT 1 FROM users WHERE username = final_username AND id != user_record.id) LOOP
            final_username := base_username || counter::TEXT;
            counter := counter + 1;
        END LOOP;
        
        UPDATE users SET username = final_username WHERE id = user_record.id;
    END LOOP;
END $$;

-- 4. Corriger les usernames dupliqués existants
DO $$
DECLARE
    user_record RECORD;
    base_username VARCHAR(50);
    final_username VARCHAR(50);
    counter INTEGER;
BEGIN
    FOR user_record IN 
        SELECT id, email, username 
        FROM users 
        WHERE username IN (
            SELECT username 
            FROM users 
            WHERE username IS NOT NULL 
            GROUP BY username 
            HAVING COUNT(*) > 1
        )
        ORDER BY created_at
    LOOP
        base_username := COALESCE(user_record.username, LOWER(SPLIT_PART(user_record.email, '@', 1)));
        final_username := base_username;
        counter := 1;
        
        -- S'assurer de l'unicité
        WHILE EXISTS (SELECT 1 FROM users WHERE username = final_username AND id != user_record.id) LOOP
            final_username := base_username || counter::TEXT;
            counter := counter + 1;
        END LOOP;
        
        UPDATE users SET username = final_username WHERE id = user_record.id;
    END LOOP;
END $$;

-- 5. Ajouter la contrainte UNIQUE
ALTER TABLE users ADD CONSTRAINT users_username_key UNIQUE (username);

-- 6. Créer l'index
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

