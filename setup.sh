#!/bin/bash

# Create required directories
mkdir -p jellyfin/data jellyfin/config jellyfin/cache

# Check if .env file exists, if not create from example
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    echo ".env file created from example. Please edit it with your configuration."
  else
    echo "No .env.example file found. Please create a .env file manually."
  fi
fi

echo "Setup complete!" 