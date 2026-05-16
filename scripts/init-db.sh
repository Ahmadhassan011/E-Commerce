#!/bin/bash
# =============================================================================
# scripts/init-db.sh — Initialize PostgreSQL database from dump file
# Supports both plain SQL (.sql) and custom-format (.dump/.custom/.pgdump) dumps
# Usage: ./init-db.sh [host] [user] [dbname] [dumpfile]
# =============================================================================

set -euo pipefail

DB_HOST="${1:-localhost}"
DB_USER="${2:-postgres}"
DB_NAME="${3:-ecommerce}"
DB_PASS="${DB_PASS:-postgres}"
DUMP_FILE="${4:-./ecommerce.sql}"

echo "=== Database Initialization ==="
echo "Host:       $DB_HOST"
echo "User:       $DB_USER"
echo "Database:   $DB_NAME"
echo "Dump File:  $DUMP_FILE"
echo ""

# Check if dump file exists
if [ ! -f "$DUMP_FILE" ]; then
  echo "ERROR: Dump file not found: $DUMP_FILE"
  echo "Usage: $0 [host] [user] [dbname] [dumpfile]"
  exit 1
fi

export PGPASSWORD="$DB_PASS"

echo "Creating database if it doesn't exist..."
psql -h "$DB_HOST" -U "$DB_USER" -tc \
  "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 \
  || psql -h "$DB_HOST" -U "$DB_USER" -c "CREATE DATABASE $DB_NAME"

# Detect dump format: pg_restore -l succeeds on custom/directory format, fails on plain SQL
if pg_restore -l "$DUMP_FILE" > /dev/null 2>&1; then
  echo "Detected custom-format dump — using pg_restore..."
  pg_restore -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" --clean --if-exists "$DUMP_FILE"
else
  echo "Detected plain SQL dump — using psql..."
  psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$DUMP_FILE"
fi

echo ""
echo "=== Database Initialization Complete ==="
echo "Database '$DB_NAME' is ready at $DB_HOST"
