#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: TimescaleDb
# Pre-backup script - Creates a SQL dump before Home Assistant backup runs
# ==============================================================================
declare BACKUP_FILE
declare POSTGRES_DATA

BACKUP_FILE="/data/backup_db.sql"
POSTGRES_DATA="/data/postgres"

bashio::log.info "Starting pre-backup process..."

# Check if postgres is running by trying to connect
if pg_isready -U postgres -h localhost -p 5432 >/dev/null 2>&1; then
    bashio::log.info "PostgreSQL is running, creating database dump..."
    
    # Remove old backup file if it exists
    if [[ -f "${BACKUP_FILE}" ]]; then
        bashio::log.debug "Removing old backup file..."
        rm -f "${BACKUP_FILE}"
    fi
    
    # Create the SQL dump
    if su - postgres -c "pg_dumpall -U postgres --clean --if-exists -f ${BACKUP_FILE}"; then
        bashio::log.info "Database dump created successfully at ${BACKUP_FILE}"
        
        # Set proper permissions
        chmod 600 "${BACKUP_FILE}"
        chown postgres:postgres "${BACKUP_FILE}"
        
        # Log file size for verification
        BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
        bashio::log.info "Backup file size: ${BACKUP_SIZE}"
    else
        bashio::log.error "Failed to create database dump!"
        # Don't fail the backup process, just log the error
        return 1
    fi
else
    bashio::log.warning "PostgreSQL is not running. Skipping database dump."
    bashio::log.warning "Note: Only file-level backup will be performed."
fi

bashio::log.info "Pre-backup process completed."
