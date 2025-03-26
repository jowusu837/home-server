FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    cifs-utils \
    && rm -rf /var/lib/apt/lists/*

# Create mount point
RUN mkdir -p /media

# Copy the mount script
COPY mount.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mount.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/mount.sh"] 