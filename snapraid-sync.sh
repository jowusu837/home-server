#!/bin/bash
# SnapRAID Sync Script
# Run this daily via cron or systemd timer

set -e

LOG_FILE="/var/log/snapraid.log"
SNAPRAID_CONF="/etc/snapraid.conf"

echo "$(date): Starting SnapRAID sync" >> "$LOG_FILE"

# Run sync to update parity
snapraid sync >> "$LOG_FILE" 2>&1

# Scrub 5% of the array to verify data integrity
snapraid scrub -p 5 >> "$LOG_FILE" 2>&1

echo "$(date): SnapRAID sync completed" >> "$LOG_FILE"

