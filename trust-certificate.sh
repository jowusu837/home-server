#!/bin/bash
# trust-certificate.sh - Export Caddy CA certificate and update system trust store
#
# This script exports the internal CA certificate from Caddy and installs it
# into the system trust store so browsers and applications trust your self-signed
# HTTPS certificates.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_FILE="$SCRIPT_DIR/caddy-root-ca.crt"
TRUST_DIR="/etc/ca-certificates/trust-source/anchors"

echo "=== Caddy CA Certificate Trust Setup ==="
echo

# Check if Caddy container is running
if ! docker ps --format '{{.Names}}' | grep -q '^caddy$'; then
    echo "Error: Caddy container is not running."
    echo "Start it with: docker-compose up -d caddy"
    exit 1
fi

# Export the CA certificate from Caddy
echo "[1/3] Exporting CA certificate from Caddy container..."
docker exec caddy cat /data/caddy/pki/authorities/local/root.crt > "$CERT_FILE"

if [[ ! -s "$CERT_FILE" ]]; then
    echo "Error: Failed to export certificate or file is empty."
    exit 1
fi

echo "      Certificate saved to: $CERT_FILE"
echo

# Install to system trust store (requires sudo)
echo "[2/3] Installing certificate to system trust store..."
echo "      (This requires sudo access)"
sudo cp "$CERT_FILE" "$TRUST_DIR/"

echo "[3/3] Updating system certificate trust..."
sudo update-ca-trust

echo
echo "=== Setup Complete ==="
echo
echo "Chromium/Chrome: Should now trust the certificate automatically."
echo
echo "Firefox: Uses its own certificate store. Either:"
echo "  - Import manually: Settings → Privacy & Security → Certificates → View Certificates → Authorities → Import"
echo "  - Or enable system certs: Set 'security.enterprise_roots.enabled' to 'true' in about:config"
echo
echo "iOS devices: Transfer '$CERT_FILE' to your device and follow the steps in README.md"
echo
