#!/bin/sh
set -eu

# Dumps the running Postgres container to a timestamped, gzipped SQL file.
# Usage: scripts/backup-db.sh [compose-file] [output-dir]
#   compose-file defaults to docker-compose.prod.yml (the real prod stack);
#   pass docker-compose.yml to back up the local dev database instead.
#   output-dir defaults to ./backups (gitignored — see .gitignore).
#
# Reads POSTGRES_USER/POSTGRES_DB from the running container's own env
# rather than a separately-sourced .env file, so it can never drift from
# whatever the container actually started with.

COMPOSE_FILE="${1:-docker-compose.prod.yml}"
OUT_DIR="${2:-backups}"

mkdir -p "$OUT_DIR"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT_FILE="$OUT_DIR/ditto-$TIMESTAMP.sql.gz"

PG_USER=$(docker compose -f "$COMPOSE_FILE" exec -T postgres printenv POSTGRES_USER)
PG_DB=$(docker compose -f "$COMPOSE_FILE" exec -T postgres printenv POSTGRES_DB)

# --clean --if-exists makes the dump itself idempotent to restore (it
# includes DROP ... IF EXISTS before each CREATE), so restore-db.sh can
# replay it straight into a database that already has the same tables.
docker compose -f "$COMPOSE_FILE" exec -T postgres pg_dump -U "$PG_USER" --clean --if-exists "$PG_DB" | gzip > "$OUT_FILE"

echo "Backed up $PG_DB to $OUT_FILE"
