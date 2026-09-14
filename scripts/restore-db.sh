#!/bin/sh
set -eu

# Restores a backup produced by backup-db.sh into a running Postgres
# container. Since that dump was taken with --clean --if-exists, replaying
# it drops and recreates every table it covers — destructive by design, so
# this prompts for confirmation unless FORCE=1 is set (for scripted use,
# e.g. a CI job restoring into a disposable throwaway database).
#
# Usage: scripts/restore-db.sh <backup-file.sql.gz> [compose-file]
#   compose-file defaults to docker-compose.prod.yml, same as backup-db.sh.

BACKUP_FILE="${1:?Usage: restore-db.sh <backup-file.sql.gz> [compose-file]}"
COMPOSE_FILE="${2:-docker-compose.prod.yml}"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "No such file: $BACKUP_FILE" >&2
  exit 1
fi

PG_USER=$(docker compose -f "$COMPOSE_FILE" exec -T postgres printenv POSTGRES_USER)
PG_DB=$(docker compose -f "$COMPOSE_FILE" exec -T postgres printenv POSTGRES_DB)

if [ "${FORCE:-}" != "1" ]; then
  printf "This will drop and restore every table in '%s'. Continue? [y/N] " "$PG_DB"
  read -r confirm
  case "$confirm" in
    y|Y) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

gunzip -c "$BACKUP_FILE" | docker compose -f "$COMPOSE_FILE" exec -T postgres psql -U "$PG_USER" -v ON_ERROR_STOP=1 "$PG_DB"

echo "Restored $PG_DB from $BACKUP_FILE"
