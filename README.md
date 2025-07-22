# Home Media Server

This repository contains configuration files for setting up a home media server using Docker Compose, with Jellyfin for media streaming.

## Features

- **Jellyfin Media Server**: Stream your media collection to any device
- **Docker Compose**: Easy deployment and management

## Prerequisites

- Docker and Docker Compose installed
- Basic understanding of networking and Docker
- Media files that you want to serve

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/jowusu837/home-media-server.git
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

## Running Docker Compose at Boot with systemd

To ensure your media server starts automatically after a reboot and only after the network is ready, you can use a systemd service:

### 1. Create a systemd Service File

Create a file at `/etc/systemd/system/home-media-server.service` with the following content (edit paths as needed):

```ini
[Unit]
Description=Home Media Server (Docker Compose)
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/victor-owusu/home-server
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

- Adjust `WorkingDirectory` to your project path if different.
- If `docker-compose` is not in `/usr/local/bin`, run `which docker-compose` to find the correct path.

### 2. Enable and Start the Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable home-media-server.service
sudo systemctl start home-media-server.service
```

This will start your containers at boot, after the network is up.

### 3. Troubleshooting
- Check status: `sudo systemctl status home-media-server.service`
- View logs: `journalctl -u home-media-server.service`
- If containers don't start, check that Docker and your network are up, and that the paths in the service file are correct.

## Configuration

The `.env` file contains all customizable parameters:

| Variable | Description | Default |
|----------|-------------|---------|
| `JELLYFIN_PORT` | Port for Jellyfin | `9097` |
| `PUID` | User ID for container permissions | `1000` |
| `PGID` | Group ID for container permissions | `1000` |
| `TZ` | Timezone | `Africa/Accra` |

### Jellyfin Configuration

   Jellyfin is configured to:
   - Mount your media directory
   - Run with specified user/group permissions

## Security Considerations

- The `.env` file contains sensitive information and should not be committed to version control

## Maintenance

### Updating Services

To update the services to the latest versions:
```bash
docker-compose pull
docker-compose up -d
```

### Common Issues

- **Permission Problems**: Check the PUID and PGID values in your .env file

## Troubleshooting

If you encounter issues:

1. Check the logs:
   ```bash
   docker-compose logs jellyfin
   ```

2. Verify your configuration:
   ```bash
   docker-compose config
   ```

3. Ensure all required directories exist and have proper permissions:
   ```bash
   ls -la jellyfin/data jellyfin/config jellyfin/cache
   ```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Jellyfin](https://jellyfin.org/)
- [Docker](https://www.docker.com/)