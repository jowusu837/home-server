#!/bin/bash

# Create required directories
mkdir -p traefik/data traefik/config traefik/certs emby/config emby/cache

# Check if .env file exists, if not create from example
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    echo ".env file created from example. Please edit it with your configuration."
  else
    echo "No .env.example file found. Please create a .env file manually."
  fi
fi

# Generate password hash for Traefik dashboard
echo -n "Do you want to generate a password hash for Traefik dashboard? (y/n): "
read generate_hash

if [ "$generate_hash" = "y" ]; then
  echo -n "Enter username: "
  read username
  echo -n "Enter password: "
  read -s password
  echo
  
  # Generate hash using htpasswd (requires apache2-utils)
  if command -v htpasswd &> /dev/null; then
    hash=$(htpasswd -nbB "$username" "$password")
    echo "Add this to your .env file for TRAEFIK_DASHBOARD_AUTH:"
    echo "$hash"
  else
    echo "htpasswd not found. Please install apache2-utils package."
  fi
fi

echo "Setup complete!" 