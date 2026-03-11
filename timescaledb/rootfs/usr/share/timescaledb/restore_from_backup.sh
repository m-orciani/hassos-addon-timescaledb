#!/command/with-contenv bashio
set -Eeuo pipefail

LOG_FILE="/var/log/timescaledb.restore.log"
BACKUP_FILE="/data/backup_db.sql"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== RESTORE START $(date) ====="
echo "Checking backup file: $BACKUP_FILE"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "ERROR: backup file not found: $BACKUP_FILE"
  exit 1
fi

ls -lah "$BACKUP_FILE"
echo "First 40 lines of backup file:"
head -n 40 "$BACKUP_FILE" || true

echo "Waiting for PostgreSQL..."
for i in $(seq 1 60); do
  if pg_isready -U postgres >/dev/null 2>&1; then
    echo "PostgreSQL is ready"
    break
  fi
  sleep 1
done

if ! pg_isready -U postgres >/dev/null 2>&1; then
  echo "ERROR: PostgreSQL not ready"
  exit 1
fi

echo "Restoring roles and databases from dump..."
psql -U postgres \
  -v ON_ERROR_STOP=1 \
  -a -e \
  -f "$BACKUP_FILE"

echo "Restore completed successfully"

echo "Roles after restore:"
psql -U postgres -Atc "\du"

echo "Databases after restore:"
psql -U postgres -Atc "\l"

echo "Tables in homeassistant.public:"
psql -U postgres -d homeassistant -Atc \
  "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;"

echo "===== RESTORE END $(date) ====="
