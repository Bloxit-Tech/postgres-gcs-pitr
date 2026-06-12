#!/usr/bin/env bash
set -euo pipefail

docker compose down

docker volume rm postgres-gcs-pitr_pgdata || true
docker volume create postgres-gcs-pitr_pgdata

docker compose run --rm \
  --entrypoint "pgbackrest --stanza=main restore" \
  postgres

docker compose up -d postgres