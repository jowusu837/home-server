#!/bin/bash

# Enable debug logging
set -x

# Function to mount the CIFS share
mount_share() {
    echo "Attempting to mount CIFS share..."
    
    # Check if mount point exists
    if [ ! -d "/media" ]; then
        echo "Creating mount point..."
        mkdir -p /media
    fi
    
    # Check if already mounted
    if mountpoint -q /media; then
        echo "Share is already mounted"
        return 0
    fi
    
    # Attempt to mount
    mount -t cifs "//${CIFS_SERVER}/${CIFS_MOUNT_POINT}" /media \
        -o "username=${CIFS_USERNAME},password=${CIFS_PASSWORD},vers=3.0,uid=1000,gid=1000,file_mode=0777,dir_mode=0777,iocharset=utf8,sec=ntlmssp"
    
    if [ $? -eq 0 ]; then
        echo "Successfully mounted CIFS share"
        return 0
    else
        echo "Failed to mount CIFS share"
        return 1
    fi
}

# Function to check if mount is active
check_mount() {
    if mountpoint -q /media && ls /media > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Main loop
echo "Starting CIFS mount manager..."
while true; do
    if ! check_mount; then
        echo "Mount check failed, attempting to mount..."
        mount_share
    else
        echo "Mount is healthy"
    fi
    sleep 300
done 