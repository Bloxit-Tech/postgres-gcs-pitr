# PostgreSQL + pgBackRest + Google Cloud Storage (PITR) Setup

## Overview

This project provides a self-hosted PostgreSQL deployment with:

* PostgreSQL 16
* Point-in-Time Recovery (PITR)
* WAL Archiving
* Automated Backups
* Google Cloud Storage Repository
* AES-256 Backup Encryption
* Docker Compose Deployment
* Automated Full and Differential Backups

The goal is to provide a low-cost alternative to managed database services while retaining enterprise-grade backup and recovery capabilities.

---

## Architecture

```text
                ┌────────────────────┐
                │    Application     │
                └─────────┬──────────┘
                          │
                          ▼
                ┌────────────────────┐
                │    PostgreSQL      │
                │                    │
                │ WAL Generation     │
                └─────────┬──────────┘
                          │
                          ▼
                ┌────────────────────┐
                │    pgBackRest      │
                │                    │
                │ Full Backups       │
                │ Differential       │
                │ WAL Archives       │
                └─────────┬──────────┘
                          │
                          ▼
                ┌────────────────────┐
                │ Google Cloud       │
                │ Storage Bucket     │
                └────────────────────┘
```

---

## Features

### Full Backups

Creates a complete database backup.

Example schedule:

```text
Every Sunday at 02:00
```

---

### Differential Backups

Stores only changes since the last full backup.

Example schedule:

```text
Monday - Saturday at 02:00
```

---

### WAL Archiving

Every transaction generates WAL files.

These files are continuously uploaded to GCS.

This enables:

* Point-in-Time Recovery
* Disaster Recovery
* Accidental Data Recovery

---

## Directory Structure

```text
postgres-gcs-pitr/
├── docker-compose.yml
├── .env
├── .gitignore
│
├── postgres/
│   └── Dockerfile
│
├── pgbackrest/
│   └── pgbackrest.conf
│
├── secrets/
│   └── gcs-key.json
│
└── scripts/
    ├── init.sh
    ├── backup-full.sh
    ├── backup-diff.sh
    ├── info.sh
    └── restore-latest.sh
```

---

## Prerequisites

### VPS

Recommended minimum:

| Resource | Value     |
| -------- | --------- |
| CPU      | 2 vCPU    |
| Memory   | 4 GB      |
| Disk     | 40 GB SSD |

Examples:

* Hetzner CX22
* Contabo VPS M
* DigitalOcean Basic Droplet

---

### Docker

Install Docker and Docker Compose.

Verify:

```bash
docker --version
docker compose version
```

---

## Google Cloud Setup

### Create Bucket

Create a bucket:

```bash
gcloud storage buckets create gs://my-postgres-backups
```

Example bucket:

```text
my-postgres-backups
```

---

### Create Service Account

Create:

```bash
gcloud iam service-accounts create pgbackrest
```

Grant permissions:

```bash
roles/storage.objectAdmin
```

---

### Generate Key

```bash
gcloud iam service-accounts keys create key.json \
  --iam-account pgbackrest@PROJECT_ID.iam.gserviceaccount.com
```

Move key:

```bash
cp key.json secrets/gcs-key.json
```

---

## Environment Variables

Create `.env`

```env
POSTGRES_USER=app
POSTGRES_PASSWORD=change_me
POSTGRES_DB=appdb
```

---

## Configure pgBackRest

Edit:

```text
pgbackrest/pgbackrest.conf
```

Replace:

```ini
repo1-gcs-bucket=YOUR_BUCKET_NAME
```

with:

```ini
repo1-gcs-bucket=my-postgres-backups
```

Generate encryption key:

```bash
openssl rand -base64 48
```

Replace:

```ini
repo1-cipher-pass=CHANGE_ME_LONG_RANDOM_SECRET
```

---

## Deployment

Build and start services:

```bash
docker compose up -d --build
```

---

## Initialize Repository

Run:

```bash
./scripts/init.sh
```

This will:

1. Start PostgreSQL
2. Create pgBackRest stanza
3. Validate repository
4. Take first full backup
5. Start backup scheduler

---

## Verify Backup Status

```bash
./scripts/info.sh
```

Expected output:

```text
stanza: main
status: ok
full backup: available
```

---

## Manual Backups

### Full Backup

```bash
./scripts/backup-full.sh
```

---

### Differential Backup

```bash
./scripts/backup-diff.sh
```

---

## Automated Schedule

Configured in the backup container:

```text
Sunday       02:00 Full Backup
Mon-Sat      02:00 Differential Backup
```

---

## Point-In-Time Recovery

Restore database to a specific timestamp.

Example:

```bash
pgbackrest \
  --stanza=main \
  --type=time \
  --target="2026-06-12 10:30:00+05" \
  restore
```

---

## Restore Latest Backup

```bash
./scripts/restore-latest.sh
```

This will:

1. Stop containers
2. Recreate database volume
3. Restore latest backup
4. Start PostgreSQL

---

## Disaster Recovery Procedure

### Scenario

VPS becomes unavailable.

### Recovery

Provision a new VPS.

Clone repository:

```bash
git clone <repository>
```

Copy:

```text
.env
secrets/gcs-key.json
```

Start services:

```bash
docker compose up -d
```

Restore:

```bash
./scripts/restore-latest.sh
```

Recovery completed.

---

## Security Recommendations

### Do Not Expose PostgreSQL Publicly

Bind to localhost:

```yaml
127.0.0.1:5432:5432
```

Use reverse proxies, VPN, SSH tunnel, or private networking.

---

### Protect Secrets

Add:

```gitignore
.env
secrets/gcs-key.json
```

Never commit credentials.

---

### Enable Firewall

Example:

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

Keep PostgreSQL private.

---

### Rotate Credentials

Regularly rotate:

* PostgreSQL passwords
* GCS service account keys
* Backup encryption key

---

## Monitoring Recommendations

For production environments:

* Uptime Kuma
* Prometheus
* Grafana
* Loki

Monitor:

* Disk usage
* CPU usage
* Memory usage
* Backup success
* WAL archive status

---

## Cost Estimate

| Item           | Monthly Cost |
| -------------- | ------------ |
| VPS            | €5–10        |
| GCS Storage    | €0–5         |
| Backup Traffic | Minimal      |
| Total          | ~€5–15       |

This provides a fully self-managed PostgreSQL deployment with automated backups and point-in-time recovery for a fraction of the cost of traditional managed database offerings.
