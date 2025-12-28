# Home Server

A self-hosted home server stack with media streaming, photo backup, and file synchronization, all running on Docker with redundant storage.

## Features

- **Jellyfin** - Media streaming server (movies, TV shows, music)
- **Immich** - Photo and video backup (iCloud/Google Photos replacement)
- **Syncthing** - Peer-to-peer file synchronization
- **mergerfs + SnapRAID** - Storage pooling with parity protection

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Arch Linux Desktop                       │
├─────────────────────────────────────────────────────────────┤
│  Docker Compose                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │  Jellyfin   │  │   Immich    │  │  Syncthing  │          │
│  │  :8096      │  │  :2283      │  │  :8384      │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
├─────────────────────────────────────────────────────────────┤
│  Storage Layer                                               │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  mergerfs (/mnt/storage)                                ││
│  │  └── /mnt/disk1 (4TB data)                              ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │  SnapRAID Parity                                        ││
│  │  └── /mnt/parity1 (4TB parity)                          ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Arch Linux with Docker and Docker Compose installed
- 2x 4TB HDDs (one for data, one for parity)
- `yay` or another AUR helper for installing mergerfs and snapraid

## Quick Start

### 1. Storage Setup (First Time Only)

Identify your drives:
```bash
lsblk -o NAME,SIZE,MODEL,SERIAL
```

Partition and format the drives:
```bash
# Partition both drives
sudo parted /dev/sda --script mklabel gpt mkpart primary ext4 0% 100%
sudo parted /dev/sdb --script mklabel gpt mkpart primary ext4 0% 100%

# Format with labels
sudo mkfs.ext4 -L disk1 /dev/sda1    # Data drive
sudo mkfs.ext4 -L parity1 /dev/sdb1  # Parity drive
```

Create mount points:
```bash
sudo mkdir -p /mnt/disk1 /mnt/parity1 /mnt/storage
```

Add to `/etc/fstab`:
```
LABEL=disk1    /mnt/disk1    ext4 defaults 0 2
LABEL=parity1  /mnt/parity1  ext4 defaults 0 2
/mnt/disk1 /mnt/storage fuse.mergerfs defaults,allow_other,use_ino,cache.files=partial,dropcacheonclose=true,category.create=mfs 0 0
```

Install required packages:
```bash
yay -S --noconfirm mergerfs snapraid
```

Mount everything:
```bash
sudo mount -a
```

### 2. Run Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

This will:
- Create all required directories
- Generate `.env.immich` with a secure password
- Install SnapRAID configuration
- Set up daily SnapRAID sync timer

### 3. Start Services

```bash
docker-compose up -d
```

### 4. Initial SnapRAID Sync

```bash
sudo snapraid sync
```

## Service Access

| Service   | URL                      | Description                    |
|-----------|--------------------------|--------------------------------|
| Jellyfin  | http://localhost:8096    | Media streaming                |
| Immich    | http://localhost:2283    | Photo/video backup             |
| Syncthing | http://localhost:8384    | File sync web UI               |

## iPhone Setup

### Photo Backup with Immich
1. Install **Immich** from the App Store
2. Open the app and enter your server URL (e.g., `http://192.168.1.x:2283`)
3. Create an account or log in
4. Enable **Background Backup** in settings
5. Grant photo library access

### File Sync with Syncthing
1. Install **Möbius Sync** from the App Store ($5)
2. Open Syncthing web UI on your server (http://localhost:8384)
3. Add your phone as a remote device using the device ID
4. Configure shared folders

## Storage Management

### SnapRAID Commands

```bash
# Run parity sync (updates parity with changes)
sudo snapraid sync

# Check data integrity
sudo snapraid scrub

# Check status
sudo snapraid status

# Fix errors (after drive replacement)
sudo snapraid fix
```

### Automated Sync

SnapRAID syncs automatically every day at 3 AM via systemd timer.

Check timer status:
```bash
systemctl status snapraid-sync.timer
```

View sync logs:
```bash
sudo journalctl -u snapraid-sync.service
```

## Directory Structure

```
/mnt/
├── disk1/                    # 4TB data drive
│   ├── jellyfin/media/       # Media files
│   ├── immich/upload/        # Photo uploads
│   ├── syncthing/data/       # Synced files
│   └── .snapraid.content     # SnapRAID metadata
├── parity1/                  # 4TB parity drive
│   └── snapraid.parity       # Parity data
└── storage/                  # mergerfs mount (use this!)
    ├── jellyfin/
    ├── immich/
    └── syncthing/

~/Work/home-server/           # This repository
├── docker-compose.yml        # Service definitions
├── setup.sh                  # Setup script
├── snapraid.conf             # SnapRAID configuration
├── snapraid-sync.sh          # Sync automation script
├── snapraid-sync.service     # Systemd service
├── snapraid-sync.timer       # Systemd timer
├── env.immich.example        # Immich env template
├── .env                      # Main environment config
├── .env.immich               # Immich environment (generated)
└── jellyfin/                 # Jellyfin config (local)
```

## Maintenance

### Update Services

```bash
docker-compose pull
docker-compose up -d
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f immich-server
docker-compose logs -f syncthing
```

### Backup Configuration

Important files to backup:
- `.env` and `.env.immich`
- `jellyfin/config/`
- `/mnt/storage/syncthing/config/`
- Immich database (use Immich's built-in backup feature)

## Expanding Storage

When adding more data drives:

1. Format and mount new drive as `/mnt/disk2`
2. Update `/etc/fstab` mergerfs line:
   ```
   /mnt/disk1:/mnt/disk2 /mnt/storage fuse.mergerfs ...
   ```
3. Update `/etc/snapraid.conf`:
   ```
   data d2 /mnt/disk2
   ```
4. Remount and sync:
   ```bash
   sudo mount -a
   sudo snapraid sync
   ```

## Troubleshooting

### Services won't start
```bash
# Check if storage is mounted
df -h /mnt/storage

# Check Docker logs
docker-compose logs
```

### Permission issues
```bash
# Ensure correct ownership
sudo chown -R $(id -u):$(id -g) /mnt/storage/
```

### Immich database issues
```bash
# Restart database
docker-compose restart immich-database

# Check database health
docker-compose exec immich-database pg_isready
```

## License

MIT License
