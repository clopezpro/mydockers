#!/bin/sh

# Exit on error
set -e

echo "--- Entrypoint: Listing /backup_scripts contents ---"
ls -l /backup_scripts/

echo "--- Entrypoint: Installing packages (apk add) ---"
apk add --no-cache mongodb-tools dcron

echo "--- Entrypoint: Copying cronjob file ---"
cp /backup_scripts/cronjob /etc/crontabs/root

echo "--- Entrypoint: Setting cronjob permissions ---"
chmod 0644 /etc/crontabs/root

echo "--- Entrypoint: Setting notificar_telegram.sh permissions ---"
chmod +x /backup_scripts/notificar_telegram.sh


echo "--- Entrypoint: Touching log file ---"
touch /var/log/cron.log

echo "--- Entrypoint: Starting crond in foreground with debug (and logging to stdout/stderr) ---"
# Using exec ensures crond becomes PID 1 for this script
# The -l 8 might be too verbose, -l 2 or 5 is often enough for cron level. 
# For now, let's keep -l 8 to see cron debug messages if backup.sh runs.
# The -L /var/log/cron.log sends cron's own logs to the file, while -f keeps crond in foreground.
# We also want to see backup.sh output in docker logs, which is handled by its redirection in cronjob file.
exec crond -f -d -l 8 -L /var/log/cron.log
