#!/usr/bin/env bash
set -euo pipefail

docker compose exec postgres pgbackrest --stanza=main --type=diff backup