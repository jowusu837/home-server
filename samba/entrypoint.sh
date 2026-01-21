#!/bin/bash
# Samba entrypoint script
# Environment variables are loaded from .env.samba via Docker Compose env_file

set -e

# Validate required environment variables
if [ -z "$SMB_PASSWORD" ]; then
    echo "ERROR: SMB_PASSWORD is not set. Please configure .env.samba"
    exit 1
fi

# Set defaults
SMB_USER="${SMB_USER:-smbuser}"

# Start samba with user and share configuration
exec /usr/bin/samba.sh \
    -u "${SMB_USER};${SMB_PASSWORD}" \
    -s "Documents;/share/Documents;yes;no;no;${SMB_USER}"
