DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_database WHERE datname = 'name_detection_app_db'
    ) THEN
        CREATE DATABASE name_detection_app_db;
    END IF;
END
$$;
-- Connect to the database using \c name_detection_app_db; in psql or your database client
