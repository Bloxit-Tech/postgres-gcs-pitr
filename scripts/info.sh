#!/usr/bin/env bash
set -euo pipefail

docker compose exec postgres pgbackrest info