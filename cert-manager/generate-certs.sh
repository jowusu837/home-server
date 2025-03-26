#!/bin/bash

# Function to generate certificates
generate_certs() {
    echo "Generating new certificates..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /certs/private.key \
        -out /certs/certificate.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=*.lan"
    
    # Set proper permissions
    chmod 600 /certs/private.key
    chmod 644 /certs/certificate.crt
    
    echo "Certificates generated successfully!"
}

# Function to check if certificates need renewal
check_renewal() {
    if [ ! -f /certs/certificate.crt ]; then
        return 0
    fi
    
    # Get expiration date
    exp_date=$(openssl x509 -enddate -noout -in /certs/certificate.crt | cut -d= -f2)
    exp_epoch=$(date -d "$exp_date" +%s)
    now_epoch=$(date +%s)
    
    # Renew if less than 30 days until expiration
    if [ $((exp_epoch - now_epoch)) -lt 2592000 ]; then
        return 0
    fi
    
    return 1
}

# Initial certificate generation
generate_certs

# Main loop for certificate renewal
while true; do
    if check_renewal; then
        generate_certs
    else
        echo "Certificates are still valid, checking again in 24 hours..."
    fi
    sleep 86400  # Check every 24 hours
done 