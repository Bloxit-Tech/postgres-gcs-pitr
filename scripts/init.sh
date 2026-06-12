#!/usr/bin/env bash
set -euo pipefail

docker compose up -d --build postgres

echo "Waiting for Postgres..."
sleep 10

docker compose exec postgres pgbackrest --stanza=main stanza-create
docker compose exec postgres pgbackrest --stanza=main check
docker compose exec postgres pgbackrest --stanza=main --type=full backup

docker compose up -d backup-cron

docker compose exec postgres pgbackrest info