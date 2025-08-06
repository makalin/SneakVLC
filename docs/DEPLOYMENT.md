# SneakVLC Deployment Guide

## Overview

This guide covers deploying SneakVLC on various platforms and environments, from local development to production servers.

## Prerequisites

- VLC with x264 support
- ffmpeg
- qrencode
- Go 1.21+
- Node.js 18+
- Git

## Local Development

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/makalin/sneakvlc.git
   cd sneakvlc
   ```

2. **Install dependencies:**
   ```bash
   ./scripts/install.sh
   ```

3. **Build the project:**
   ```bash
   make build
   ```

4. **Run the application:**
   ```bash
   make all
   ```

5. **Access the application:**
   - Web UI: http://localhost:3000
   - API: http://localhost:8080

### Development Mode

For development with hot reloading:

```bash
# Terminal 1: Backend
make backend-run

# Terminal 2: Frontend
make web-dev
```

## Docker Deployment

### Using Docker Compose

1. **Build and run:**
   ```bash
   docker-compose up --build
   ```

2. **Run in background:**
   ```bash
   docker-compose up -d
   ```

3. **View logs:**
   ```bash
   docker-compose logs -f
   ```

### Using Docker directly

1. **Build the image:**
   ```bash
   docker build -t sneakvlc .
   ```

2. **Run the container:**
   ```bash
   docker run -p 8080:8080 -p 3000:3000 -p 12345:12345/udp sneakvlc
   ```

### Docker with volumes

```bash
docker run -d \
  --name sneakvlc \
  -p 8080:8080 \
  -p 3000:3000 \
  -p 12345:12345/udp \
  -v $(pwd)/received:/app/received \
  -v $(pwd)/tmp:/tmp/sneakvlc \
  sneakvlc
```

## Production Deployment

### System Requirements

- **CPU:** 1+ cores
- **RAM:** 512MB+ (2GB recommended)
- **Storage:** 1GB+ available space
- **Network:** UDP port 12345 open for VLC streaming

### Ubuntu/Debian Server

1. **Install dependencies:**
   ```bash
   sudo apt update
   sudo apt install -y vlc ffmpeg qrencode golang-go nodejs npm git
   ```

2. **Clone and setup:**
   ```bash
   git clone https://github.com/makalin/sneakvlc.git
   cd sneakvlc
   ./scripts/install.sh --setup
   ```

3. **Build for production:**
   ```bash
   make build
   ```

4. **Create systemd service:**
   ```bash
   sudo tee /etc/systemd/system/sneakvlc.service << EOF
   [Unit]
   Description=SneakVLC P2P File Transfer
   After=network.target

   [Service]
   Type=simple
   User=sneakvlc
   WorkingDirectory=/opt/sneakvlc
   ExecStart=/opt/sneakvlc/bin/sneakvlc
   Restart=always
   RestartSec=5
   Environment=SERVER_PORT=8080
   Environment=SERVER_HOST=0.0.0.0

   [Install]
   WantedBy=multi-user.target
   EOF
   ```

5. **Setup user and permissions:**
   ```bash
   sudo useradd -r -s /bin/false sneakvlc
   sudo mkdir -p /opt/sneakvlc
   sudo cp -r bin web/dist scripts /opt/sneakvlc/
   sudo chown -R sneakvlc:sneakvlc /opt/sneakvlc
   ```

6. **Enable and start service:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable sneakvlc
   sudo systemctl start sneakvlc
   ```

7. **Check status:**
   ```bash
   sudo systemctl status sneakvlc
   ```

### CentOS/RHEL Server

1. **Install dependencies:**
   ```bash
   sudo yum update -y
   sudo yum install -y vlc ffmpeg qrencode golang nodejs npm git
   ```

2. **Follow the same setup as Ubuntu/Debian above.**

### macOS Server

1. **Install dependencies:**
   ```bash
   brew install vlc ffmpeg qrencode go node git
   ```

2. **Setup as a launchd service:**
   ```bash
   # Create plist file
   cat > ~/Library/LaunchAgents/com.sneakvlc.plist << EOF
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.sneakvlc</string>
       <key>ProgramArguments</key>
       <array>
           <string>/opt/sneakvlc/bin/sneakvlc</string>
       </array>
       <key>WorkingDirectory</key>
       <string>/opt/sneakvlc</string>
       <key>RunAtLoad</key>
       <true/>
       <key>KeepAlive</key>
       <true/>
       <key>StandardOutPath</key>
       <string>/var/log/sneakvlc.log</string>
       <key>StandardErrorPath</key>
       <string>/var/log/sneakvlc.error.log</string>
   </dict>
   </plist>
   EOF

   # Load the service
   launchctl load ~/Library/LaunchAgents/com.sneakvlc.plist
   ```

## Cloud Deployment

### AWS EC2

1. **Launch EC2 instance:**
   - AMI: Ubuntu 22.04 LTS
   - Instance type: t3.small or larger
   - Security group: Allow ports 22, 80, 443, 8080, 3000, 12345

2. **Connect and deploy:**
   ```bash
   ssh ubuntu@your-instance-ip
   git clone https://github.com/makalin/sneakvlc.git
   cd sneakvlc
   ./scripts/install.sh
   make build
   ```

3. **Run with PM2 (recommended):**
   ```bash
   npm install -g pm2
   pm2 start bin/sneakvlc --name sneakvlc
   pm2 startup
   pm2 save
   ```

### Google Cloud Platform

1. **Create Compute Engine instance:**
   ```bash
   gcloud compute instances create sneakvlc \
     --zone=us-central1-a \
     --machine-type=e2-small \
     --image-family=ubuntu-2204-lts \
     --image-project=ubuntu-os-cloud \
     --tags=sneakvlc
   ```

2. **Configure firewall:**
   ```bash
   gcloud compute firewall-rules create sneakvlc \
     --allow tcp:8080,tcp:3000,udp:12345 \
     --target-tags=sneakvlc
   ```

3. **Deploy application:**
   ```bash
   gcloud compute ssh sneakvlc
   # Follow the same setup as AWS EC2
   ```

### DigitalOcean Droplet

1. **Create droplet:**
   - Image: Ubuntu 22.04 LTS
   - Size: Basic $6/month or larger
   - Add SSH key

2. **Deploy application:**
   ```bash
   ssh root@your-droplet-ip
   # Follow the same setup as AWS EC2
   ```

## Reverse Proxy Setup

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Web interface
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # API
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket
    location /ws {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Apache Configuration

```apache
<VirtualHost *:80>
    ServerName your-domain.com

    # Web interface
    ProxyPreserveHost On
    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/

    # API
    ProxyPass /api/ http://localhost:8080/api/
    ProxyPassReverse /api/ http://localhost:8080/api/

    # WebSocket
    RewriteEngine on
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/ws(.*)$ "ws://localhost:8080/ws$1" [P,L]
</VirtualHost>
```

## SSL/TLS Configuration

### Let's Encrypt with Certbot

1. **Install Certbot:**
   ```bash
   sudo apt install certbot python3-certbot-nginx
   ```

2. **Obtain certificate:**
   ```bash
   sudo certbot --nginx -d your-domain.com
   ```

3. **Auto-renewal:**
   ```bash
   sudo crontab -e
   # Add: 0 12 * * * /usr/bin/certbot renew --quiet
   ```

## Monitoring and Logging

### Log Management

```bash
# View application logs
sudo journalctl -u sneakvlc -f

# View Docker logs
docker-compose logs -f

# View PM2 logs
pm2 logs sneakvlc
```

### Health Checks

```bash
# Check API health
curl http://localhost:8080/health

# Check service status
sudo systemctl status sneakvlc

# Check Docker container
docker ps
```

### Performance Monitoring

```bash
# Monitor system resources
htop

# Monitor network usage
iftop

# Monitor disk usage
df -h
```

## Troubleshooting

### Common Issues

1. **Port already in use:**
   ```bash
   sudo netstat -tulpn | grep :8080
   sudo kill -9 <PID>
   ```

2. **Permission denied:**
   ```bash
   sudo chown -R $USER:$USER /opt/sneakvlc
   chmod +x /opt/sneakvlc/bin/sneakvlc
   ```

3. **VLC not found:**
   ```bash
   sudo apt install vlc
   # or
   brew install vlc
   ```

4. **WebSocket connection failed:**
   - Check firewall settings
   - Verify proxy configuration
   - Check browser console for errors

### Debug Mode

```bash
# Run with debug logging
DEBUG=* ./bin/sneakvlc

# Run with verbose output
./bin/sneakvlc -v
```

## Backup and Recovery

### Backup Strategy

1. **Application files:**
   ```bash
   tar -czf sneakvlc-backup-$(date +%Y%m%d).tar.gz /opt/sneakvlc
   ```

2. **Configuration:**
   ```bash
   cp /etc/systemd/system/sneakvlc.service /backup/
   cp /etc/nginx/sites-available/sneakvlc /backup/
   ```

3. **Database (if using):**
   ```bash
   # Currently no database, but prepare for future
   ```

### Recovery

1. **Restore from backup:**
   ```bash
   tar -xzf sneakvlc-backup-20240101.tar.gz -C /
   sudo systemctl restart sneakvlc
   ```

2. **Fresh installation:**
   ```bash
   git clone https://github.com/makalin/sneakvlc.git
   cd sneakvlc
   ./scripts/install.sh
   make build
   ``` 