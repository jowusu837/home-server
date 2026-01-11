# Home Server

A self-hosted home server stack with media streaming, photo backup, and automated backups, all running on Docker with redundant storage.

## Features

- **Jellyfin** - Media streaming server (movies, TV shows, music)
- **Immich** - Photo and video backup (iCloud/Google Photos replacement)
- **Vaultwarden** - Self-hosted password manager (Bitwarden-compatible)
- **Rsync Backup** - Automated daily backup of home folders (Documents, Downloads, Music)
- **mergerfs + SnapRAID** - Storage pooling with parity protection

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Arch Linux Desktop                       │
├─────────────────────────────────────────────────────────────┤
│  Docker Compose                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Jellyfin   │  │   Immich    │  │ Vaultwarden │         │
│  │  :8096      │  │   :2283     │  │   :8222     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
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
- Set up daily SnapRAID sync timer (3 AM)
- Set up daily rsync backup timer (2 AM)

### 3. Start Services

```bash
docker-compose up -d
```

### 4. Initial SnapRAID Sync

```bash
sudo snapraid sync
```

## Service Access

| Service         | URL                           | Description                    |
|-----------------|-------------------------------|--------------------------------|
| Jellyfin        | http://localhost:8096         | Media streaming                |
| Immich          | http://localhost:2283         | Photo/video backup             |
| Vaultwarden     | http://localhost:8222         | Password manager               |
| Vaultwarden Admin | http://localhost:8222/admin | Admin panel (use ADMIN_TOKEN)  |

## iPhone Setup

### Photo Backup with Immich
1. Install **Immich** from the App Store
2. Open the app and enter your server URL (e.g., `http://192.168.1.x:2283`)
3. Create an account or log in
4. Enable **Background Backup** in settings
5. Grant photo library access

### Password Manager with Bitwarden
1. Install **Bitwarden** from the App Store
2. Tap the gear icon on the login screen
3. Select **Self-hosted** and enter: `http://192.168.1.x:8222`
4. Create an account or log in
5. Enable **Face ID/Touch ID** for quick access

## Vaultwarden Setup

### Initial Configuration
1. Access the web vault at `http://localhost:8222`
2. Create your account (first user)
3. **Important:** After creating accounts, disable public signups:
   ```bash
   # Edit .env and set:
   VAULTWARDEN_SIGNUPS_ALLOWED=false
   
   # Restart the container
   docker-compose up -d vaultwarden
   ```

### Admin Panel
Access the admin panel at `http://localhost:8222/admin` using the `VAULTWARDEN_ADMIN_TOKEN` from your `.env` file.

From the admin panel you can:
- View all registered users
- Invite new users
- Manage organization settings
- View server configuration

### Browser Extensions
1. Install the official **Bitwarden** extension (Firefox/Chrome/Edge)
2. Click the extension icon → Settings (gear)
3. Select **Self-hosted** environment
4. Enter server URL: `http://localhost:8222`
5. Log in with your account

### Desktop Apps
1. Download from [bitwarden.com/download](https://bitwarden.com/download/)
2. Settings → Self-hosted → Enter server URL
3. Log in with your account

### CLI Tool (Optional)
```bash
npm install -g @bitwarden/cli
bw config server http://localhost:8222
bw login
```

### Security Recommendations
- **Enable 2FA** for all accounts via web vault settings
- **Disable admin panel** after initial setup (set `ADMIN_TOKEN=` empty in `.env`)
- Store the admin token securely offline
- Regular backups are automated (daily at 1:30 AM)

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

### Automated Backup

Home folders are backed up automatically every day at 2 AM via rsync.

**Backed up folders:**
- `~/Documents` → `/mnt/storage/Documents/`
- `~/Downloads` → `/mnt/storage/Downloads/`
- `~/Music` → `/mnt/storage/Music/`

Check timer status:
```bash
systemctl status rsync-backup.timer
```

Run backup manually:
```bash
sudo systemctl start rsync-backup.service
```

View backup logs:
```bash
cat /var/log/rsync-backup.log
```

**Note:** Deleted files are preserved in the backup (rsync runs without `--delete`).

### Vaultwarden Data Protection

Vaultwarden data is stored at `/mnt/storage/vaultwarden/data` and protected by SnapRAID parity.

**Critical files:**
- `db.sqlite3` — Main database (passwords, settings)
- `rsa_key.*` — Encryption keys (required for data recovery)
- `attachments/` — File attachments
- `sends/` — Bitwarden Send files

## Directory Structure

```
/mnt/
├── disk1/                    # 4TB data drive
│   ├── jellyfin/media/       # Media files
│   ├── immich/upload/        # Photo uploads
│   ├── vaultwarden/data/     # Password vault data
│   └── .snapraid.content     # SnapRAID metadata
├── parity1/                  # 4TB parity drive
│   └── snapraid.parity       # Parity data
└── storage/                  # mergerfs mount (use this!)
    ├── jellyfin/
    ├── immich/
    ├── vaultwarden/          # Password manager data
    ├── Documents/            # Backup of ~/Documents
    ├── Downloads/            # Backup of ~/Downloads
    └── Music/                # Backup of ~/Music

~/Work/home-server/           # This repository
├── docker-compose.yml        # Service definitions
├── setup.sh                  # Setup script
├── snapraid.conf             # SnapRAID configuration
├── snapraid-sync.sh          # SnapRAID sync script
├── snapraid-sync.service     # SnapRAID systemd service
├── snapraid-sync.timer       # SnapRAID systemd timer
├── rsync-backup.sh           # Rsync backup script
├── rsync-backup.service      # Rsync systemd service
├── rsync-backup.timer        # Rsync systemd timer
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
docker-compose logs -f jellyfin
```

### Backup Configuration

Important files to backup:
- `.env` and `.env.immich` (contains secrets!)
- `jellyfin/config/`
- Immich database (use Immich's built-in backup feature)
- Vaultwarden data (protected by SnapRAID at `/mnt/storage/vaultwarden/`)

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

### Vaultwarden issues
```bash
# Check container logs
docker-compose logs vaultwarden

# Restart container
docker-compose restart vaultwarden

# Verify data directory permissions
ls -la /mnt/storage/vaultwarden/data
```

### Restore Vaultwarden after drive failure
```bash
# If a data drive fails, use SnapRAID to recover:
sudo snapraid fix

# Then restart Vaultwarden
docker-compose restart vaultwarden
```

## License

MIT License
