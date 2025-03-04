# Home Media Server

This repository contains configuration files for setting up a home media server using Docker Compose, with Emby for media streaming and Traefik as a reverse proxy.

## Features

- **Emby Media Server**: Stream your media collection to any device
- **Traefik Reverse Proxy**: Secure access with automatic SSL certificates
- **Docker Compose**: Easy deployment and management
- **Environment Configuration**: Customizable setup via environment variables

## Prerequisites

- Docker and Docker Compose installed
- Basic understanding of networking and Docker
- Media files that you want to serve

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/home-media-server.git
   cd home-media-server
   ```

2. Run the setup script to create necessary directories and configure your environment:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   
   The script will:
   - Create required directories
   - Copy `.env.example` to `.env` if it doesn't exist
   - Help you generate a password hash for the Traefik dashboard

3. Edit the `.env` file with your specific configuration:
   ```bash
   nano .env
   ```

4. Start the services:
   ```bash
   docker-compose up -d
   ```

5. Access your services:
   - Emby: `https://media.server` (or your configured domain)
   - Traefik Dashboard: `https://gateway.server` (or your configured domain)

## Configuration

### Environment Variables

The `.env` file contains all customizable parameters:

| Variable | Description | Default |
|----------|-------------|---------|
| `DOMAIN` | Base domain for your services | `server` |
| `TRAEFIK_SUBDOMAIN` | Subdomain for Traefik dashboard | `gateway` |
| `EMBY_SUBDOMAIN` | Subdomain for Emby | `media` |
| `PUID` | User ID for container permissions | `1000` |
| `PGID` | Group ID for container permissions | `1000` |
| `TZ` | Timezone | `Africa/Accra` |
| `MEDIA_PATH` | Path to your media files | Required |
| `TRAEFIK_DASHBOARD_AUTH` | HTTP Basic Auth for Traefik dashboard | Required |
| `ACME_EMAIL` | Email for Let's Encrypt | Required |
| `EMBY_PORT` | Internal port for Emby | `8096` |

### Traefik Configuration

Traefik is configured to:
- Redirect HTTP to HTTPS
- Automatically obtain SSL certificates from Let's Encrypt
- Provide a secure dashboard with basic authentication
- Apply security headers to all responses

### Emby Configuration

Emby is configured to:
- Mount your media directory
- Run with specified user/group permissions
- Be accessible through Traefik with SSL

## Security Considerations

- The `.env` file contains sensitive information and should not be committed to version control
- The Traefik dashboard is protected with basic authentication
- All connections are secured with SSL

## Maintenance

### Updating Services

To update the services to the latest versions:
```bash
docker-compose pull
docker-compose up -d
```

### Common Issues

- **SSL Certificate Issues**: Ensure your domain is correctly pointing to your server's IP
- **Permission Problems**: Check the PUID and PGID values in your .env file
- **Media Not Showing**: Verify the path in MEDIA_PATH and ensure it's accessible

## Troubleshooting

If you encounter issues:

1. Check the logs:
   ```bash
   docker-compose logs traefik
   docker-compose logs emby
   ```

2. Verify your configuration:
   ```bash
   docker-compose config
   ```

3. Ensure all required directories exist and have proper permissions:
   ```bash
   ls -la traefik/data traefik/config traefik/certs emby/config emby/cache
   ```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Traefik](https://traefik.io/)
- [Emby](https://emby.media/)
- [Docker](https://www.docker.com/)