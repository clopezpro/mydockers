#!/bin/sh

# Exit on error and print commands
set -e
set -x

# Environment variables (passed from docker-compose)
# MONGO_HOST, MONGO_PORT, MONGO_DB
# MONGO_USER, MONGO_PASS, MONGO_AUTH_DB (optional)
# BACKUP_KEEP_COUNT (e.g., 4)

BACKUP_DIR="/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Ensure MONGO_DB is set
if [ -z "${MONGO_URL}" ]; then
  echo "$(date): MONGO_URL environment variable is not set. Exiting."
  exit 1
fi

BACKUP_NAME="${MONGO_DB}_${TIMESTAMP}.gz"
BACKUP_FILE_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Construct mongodump command
CMD="mongodump --uri \"${MONGO_URL}\" --db \"${MONGO_DB}\" --archive=\"${BACKUP_FILE_PATH}\" --gzip --authenticationDatabase \"${MONGO_DB}\""

echo "$(date): Starting backup for database '${MONGO_DB}' using URI (first 30 chars): $(echo ${MONGO_URL} | cut -c 1-30)..."

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Perform the mongodump
echo "$(date): Executing: sh -c '${CMD}'" # Log the command for debugging, password will be visible in logs
sh -c "${CMD}"

if [ $? -eq 0 ]; then
  echo "$(date): Backup successful: ${BACKUP_FILE_PATH}"
else
  echo "$(date): Backup failed!"
  exit 1
fi

# Prune old backups
echo "$(date): Pruning old backups in ${BACKUP_DIR} for database '${MONGO_DB}', keeping last ${BACKUP_KEEP_COUNT}..."

# Ensure BACKUP_KEEP_COUNT is a positive integer
if ! [[ "${BACKUP_KEEP_COUNT}" =~ ^[0-9]+$ ]] || [ "${BACKUP_KEEP_COUNT}" -lt 1 ]; then
    echo "$(date): Invalid BACKUP_KEEP_COUNT: ${BACKUP_KEEP_COUNT}. Must be a positive integer. Skipping prune."
    # Decide if to exit with error or success if pruning config is bad. Success for now.
    echo "$(date): Backup script finished for database '${MONGO_DB}'."
    exit 0
fi

cd "${BACKUP_DIR}"
# Count current backups for this DB
# Ensure we only count files matching the pattern MONGO_DB_*.gz
MATCHING_FILES_COUNT=$(ls -1 "${MONGO_DB}"_*.gz 2>/dev/null | wc -l)

if [ "${MATCHING_FILES_COUNT}" -gt "${BACKUP_KEEP_COUNT}" ]; then
    NUM_TO_DELETE=$((MATCHING_FILES_COUNT - BACKUP_KEEP_COUNT))
    echo "$(date): Found ${MATCHING_FILES_COUNT} backups for '${MONGO_DB}'. Need to delete ${NUM_TO_DELETE} oldest backup(s)."
    # List files matching the pattern, sort by name (chronological due to timestamp), oldest first.
    # Then take the top NUM_TO_DELETE oldest ones and remove them.
    ls -1r "${MONGO_DB}"_*.gz 2>/dev/null | tail -n "${NUM_TO_DELETE}" | xargs -I {} rm -f -- "./{}"
    echo "$(date): Pruned ${NUM_TO_DELETE} old backup(s) for database '${MONGO_DB}'."
else
    echo "$(date): No old backups to prune for database '${MONGO_DB}'. Found ${MATCHING_FILES_COUNT} backup(s), limit is ${BACKUP_KEEP_COUNT}."
fi

echo "$(date): Backup and pruning complete for database '${MONGO_DB}'."
