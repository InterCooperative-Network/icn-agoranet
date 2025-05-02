#!/bin/bash
# Reset AgoraNet database for integration testing

set -e

# Default connection parameters (can be overridden via env vars)
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-agoranet}
DB_PASS=${DB_PASS:-agoranet}
DB_NAME=${DB_NAME:-agoranet}

# Check if we're running in Docker environment
if [ -n "$DOCKER_ENV" ]; then
  # If in Docker, use the docker-compose exec command
  echo "Resetting AgoraNet database in Docker environment..."
  docker-compose -f docker-compose.integration.yml exec -T postgres psql -U $DB_USER -d $DB_NAME -c "
    -- Truncate all tables except migrations
    DO \$\$
    DECLARE
      tbl text;
    BEGIN
      FOR tbl IN
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema='public' AND table_type='BASE TABLE'
        AND table_name != '_sqlx_migrations'
      LOOP
        EXECUTE 'TRUNCATE TABLE ' || tbl || ' CASCADE';
      END LOOP;
    END \$\$;
  "
else
  # If running locally, use direct connection
  echo "Resetting AgoraNet database..."
  PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
    -- Truncate all tables except migrations
    DO \$\$
    DECLARE
      tbl text;
    BEGIN
      FOR tbl IN
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema='public' AND table_type='BASE TABLE'
        AND table_name != '_sqlx_migrations'
      LOOP
        EXECUTE 'TRUNCATE TABLE ' || tbl || ' CASCADE';
      END LOOP;
    END \$\$;
  "
fi

echo "Database reset complete!" 