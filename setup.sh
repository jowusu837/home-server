#!/bin/bash

# Home Server Setup Script
# This script prepares the environment for running the home server stack

set -e

echo "=== Home Server Setup ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root for certain operations
check_storage_mounted() {
    if mountpoint -q /mnt/storage 2>/dev/null; then
        echo -e "${GREEN}✓ Storage mounted at /mnt/storage${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Storage not mounted at /mnt/storage${NC}"
        echo "  Please ensure mergerfs is configured and mounted."
        echo "  Run: sudo mount -a"
        return 1
    fi
}

# Create Jellyfin directories (local config)
create_jellyfin_dirs() {
    echo "Creating Jellyfin directories..."
    mkdir -p jellyfin/config jellyfin/cache
    echo -e "${GREEN}✓ Jellyfin local directories created${NC}"
}

# Create storage directories on merged storage
create_storage_dirs() {
    echo "Creating storage directories..."
    
    if [ -d "/mnt/storage" ]; then
        # Jellyfin directories (config, cache, media)
        sudo mkdir -p /mnt/storage/jellyfin/config
        sudo mkdir -p /mnt/storage/jellyfin/cache
        sudo mkdir -p /mnt/storage/jellyfin/media
        
        # Immich directories (uploads, library, database)
        sudo mkdir -p /mnt/storage/immich/upload
        sudo mkdir -p /mnt/storage/immich/library
        sudo mkdir -p /mnt/storage/immich/pgdata
        
        # Set ownership to current user
        sudo chown -R $(id -u):$(id -g) /mnt/storage/jellyfin
        sudo chown -R $(id -u):$(id -g) /mnt/storage/immich
        
        echo -e "${GREEN}✓ Storage directories created${NC}"
    else
        echo -e "${RED}✗ /mnt/storage does not exist. Please set up mergerfs first.${NC}"
        return 1
    fi
}

# Create SnapRAID content directory
create_snapraid_dirs() {
    echo "Creating SnapRAID directories..."
    sudo mkdir -p /var/snapraid
    echo -e "${GREEN}✓ SnapRAID directories created${NC}"
}

# Setup environment files
setup_env_files() {
    echo "Setting up environment files..."
    
    # Main .env file
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            echo -e "${GREEN}✓ .env created from example${NC}"
        else
            cat > .env << 'EOF'
# Home Server Environment Configuration
PUID=1000
PGID=1000
TZ=Africa/Accra
HOST_IP=server.lan
EOF
            echo -e "${GREEN}✓ .env created with defaults${NC}"
        fi
    else
        echo -e "${YELLOW}• .env already exists, skipping${NC}"
    fi
    
    # Immich .env file
    if [ ! -f .env.immich ]; then
        if [ -f env.immich.example ]; then
            cp env.immich.example .env.immich
            # Generate a random password
            NEW_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24)
            sed -i "s/changeme_use_strong_password/$NEW_PASSWORD/" .env.immich
            echo -e "${GREEN}✓ .env.immich created with secure password${NC}"
            echo -e "${YELLOW}  Password saved in .env.immich - keep this file secure!${NC}"
        else
            echo -e "${RED}✗ env.immich.example not found${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}• .env.immich already exists, skipping${NC}"
    fi
}

# Install SnapRAID configuration
install_snapraid_config() {
    echo "Installing SnapRAID configuration..."
    
    if [ -f snapraid.conf ]; then
        sudo cp snapraid.conf /etc/snapraid.conf
        echo -e "${GREEN}✓ SnapRAID config installed to /etc/snapraid.conf${NC}"
    else
        echo -e "${YELLOW}⚠ snapraid.conf not found in current directory${NC}"
    fi
}

# Install SnapRAID systemd timer
install_snapraid_timer() {
    echo "Installing SnapRAID automation..."
    
    if [ -f snapraid-sync.sh ] && [ -f snapraid-sync.service ] && [ -f snapraid-sync.timer ]; then
        # Make script executable
        chmod +x snapraid-sync.sh
        
        # Install systemd files
        sudo cp snapraid-sync.service /etc/systemd/system/
        sudo cp snapraid-sync.timer /etc/systemd/system/
        
        # Update service file path
        sudo sed -i "s|ExecStart=.*|ExecStart=$(pwd)/snapraid-sync.sh|" /etc/systemd/system/snapraid-sync.service
        
        # Enable timer
        sudo systemctl daemon-reload
        sudo systemctl enable snapraid-sync.timer
        sudo systemctl start snapraid-sync.timer
        
        echo -e "${GREEN}✓ SnapRAID timer installed and enabled${NC}"
        echo "  Sync runs daily at 3 AM"
    else
        echo -e "${YELLOW}⚠ SnapRAID automation files not found${NC}"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "=== Setup Complete ==="
    echo ""
    echo "Next steps:"
    echo "1. Review and update .env.immich with a secure password (if not auto-generated)"
    echo "2. Start the services: docker-compose up -d"
    echo "3. Access the services:"
    echo "   - Jellyfin:  http://localhost:8096"
    echo "   - Immich:    http://localhost:2283"
    echo ""
    echo "4. Run initial SnapRAID sync: sudo snapraid sync"
    echo ""
    echo "For iPhone setup:"
    echo "   - Install 'Immich' app from App Store for photo backup"
    echo ""
}

# Main execution
main() {
    # Check storage first
    check_storage_mounted || echo -e "${YELLOW}Continuing without mounted storage...${NC}"
    echo ""
    
    # Create directories
    create_jellyfin_dirs
    create_storage_dirs || true
    create_snapraid_dirs || true
    echo ""
    
    # Setup configuration
    setup_env_files
    echo ""
    
    # Install SnapRAID config and automation
    install_snapraid_config || true
    install_snapraid_timer || true
    echo ""
    
    # Print summary
    print_summary
}

# Run main function
main "$@"
