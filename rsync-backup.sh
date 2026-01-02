#!/bin/bash
# Daily backup of home folders to storage

# Use absolute path since $HOME is not set correctly when running via systemd/sudo
USER_HOME="/home/vowusu"
BACKUP_DIR="/mnt/storage"
LOG_FILE="/var/log/rsync-backup.log"

echo "=== Backup started: $(date) ===" >> "$LOG_FILE"

# Backup each folder (no --delete to preserve deleted files)
rsync -av "$USER_HOME/Documents/" "$BACKUP_DIR/Documents/" >> "$LOG_FILE" 2>&1
rsync -av "$USER_HOME/Downloads/" "$BACKUP_DIR/Downloads/" >> "$LOG_FILE" 2>&1
rsync -av "$USER_HOME/Music/"     "$BACKUP_DIR/Music/"     >> "$LOG_FILE" 2>&1

echo "=== Backup completed: $(date) ===" >> "$LOG_FILE"

