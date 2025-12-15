#!/bin/bash
set -e

# CoCounsel Database Initialization Script
# This script runs automatically when the database container first starts

echo "================================================"
echo "CoCounsel Database Initialization"
echo "================================================"

# Create extensions
echo "Creating PostgreSQL extensions..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Enable pgvector for vector embeddings
    CREATE EXTENSION IF NOT EXISTS vector;
    
    -- Enable UUID generation
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    -- Enable HTTP requests (for embedding generation)
    -- CREATE EXTENSION IF NOT EXISTS http;
    
    -- Enable pg_cron for scheduled tasks (optional)
    -- CREATE EXTENSION IF NOT EXISTS pg_cron;
EOSQL

echo "✓ Extensions created"

# Create application users
echo "Creating application users..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Application user for n8n workflows
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'cocounsel_app') THEN
            CREATE USER cocounsel_app WITH PASSWORD '$POSTGRES_PASSWORD';
        END IF;
    END
    \$\$;
    
    -- Grant permissions
    GRANT CONNECT ON DATABASE $POSTGRES_DB TO cocounsel_app;
    GRANT USAGE ON SCHEMA public TO cocounsel_app;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cocounsel_app;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cocounsel_app;
    
    -- Set default privileges for future tables
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO cocounsel_app;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO cocounsel_app;
EOSQL

echo "✓ Application users created"

# Create n8n schema
echo "Creating n8n schema..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create separate schema for n8n
    CREATE SCHEMA IF NOT EXISTS n8n;
    
    -- Grant permissions to n8n schema
    GRANT USAGE ON SCHEMA n8n TO cocounsel_app;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA n8n TO cocounsel_app;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA n8n TO cocounsel_app;
    
    -- Set default privileges
    ALTER DEFAULT PRIVILEGES IN SCHEMA n8n GRANT ALL ON TABLES TO cocounsel_app;
    ALTER DEFAULT PRIVILEGES IN SCHEMA n8n GRANT ALL ON SEQUENCES TO cocounsel_app;
EOSQL

echo "✓ n8n schema created"

# Verify extensions
echo "Verifying extensions..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 
        extname AS "Extension",
        extversion AS "Version"
    FROM pg_extension
    WHERE extname IN ('vector', 'uuid-ossp')
    ORDER BY extname;
EOSQL

echo ""
echo "================================================"
echo "Database initialization complete!"
echo "================================================"
echo "Database: $POSTGRES_DB"
echo "Admin User: $POSTGRES_USER"
echo "App User: cocounsel_app"
echo "Extensions: vector, uuid-ossp"
echo "================================================"
