FROM alpine:3.17

# Install required packages
RUN apk add --no-cache \
    openssl \
    bash \
    tzdata

# Create certificates directory
RUN mkdir -p /certs

# Copy the certificate generation script
COPY generate-certs.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate-certs.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/generate-certs.sh"] 