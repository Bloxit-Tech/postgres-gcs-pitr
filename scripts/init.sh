#!/usr/bin/env bash
set -euo pipefail

docker compose up -d --build postgres

echo "Waiting for Postgres..."
until docker compose exec -u postgres postgres pg_isready -U "${POSTGRES_USER:-app}" -d "${POSTGRES_DB:-appdb}" >/dev/null 2>&1; do
  sleep 2
done

docker compose exec -u postgres postgres pgbackrest --stanza=main stanza-create
docker compose exec -u postgres postgres pgbackrest --stanza=main check
docker compose exec -u postgres postgres pgbackrest --stanza=main --type=full backup

docker compose up -d backup-cron

docker compose exec -u postgres postgres pgbackrest info