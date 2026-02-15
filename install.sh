#!/bin/bash
# Ralph TUI Monitor Installer

set -e

MONITOR_DIR="$HOME/ralph-monitor"

echo "==================================="
echo "  Ralph TUI Monitor - Telepítő"
echo "==================================="
echo ""

# 1. Create directory
echo "[1/6] Könyvtár létrehozása..."
mkdir -p "$MONITOR_DIR"

# 2. Copy files
echo "[2/6] Fájlok másolása..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -r "$SCRIPT_DIR/public" "$MONITOR_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/ralph-monitor.sh" "$MONITOR_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/ralph-tui-monitor.sh" "$MONITOR_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/server.js" "$MONITOR_DIR/" 2>/dev/null || true

# 3. Install npm dependencies
echo "[3/6] NPM függőségek telepítése..."
cd "$MONITOR_DIR"
npm install express 2>/dev/null || true

# 4. Nginx config
echo "[4/6] Nginx konfiguráció..."
NGINX_CONF="server {
    listen 8080;
    server_name _;
    root $MONITOR_DIR/public;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}"

echo "$NGINX_CONF" | sudo tee /etc/nginx/sites-available/ralph-monitor > /dev/null
sudo ln -sf /etc/nginx/sites-available/ralph-monitor /etc/nginx/sites-enabled/
sudo ufw allow 8080/tcp 2>/dev/null || true
sudo nginx -s reload 2>/dev/null || sudo nginx

# 5. Add aliases to bashrc
echo "[5/6] Aliasok hozzáadása ~/.bashrc-hoz..."
ALIASES="
# Ralph Monitor
alias rmon='$MONITOR_DIR/ralph-monitor.sh'
alias rmontui='$MONITOR_DIR/ralph-tui-monitor.sh'

rmon() {
    $MONITOR_DIR/ralph-monitor.sh \"\$@\"
}
rmon_status() {
    $MONITOR_DIR/ralph-monitor.sh status
}
rmon_tasks() {
    $MONPHA_DIR/ralph-monitor.sh tasks
}
rmon_running() {
    $MONITOR_DIR/ralph-monitor.sh running
}
rmon_watch() {
    $MONITOR_DIR/ralph-monitor.sh watch
}
rmon_connect() {
    $MONITOR_DIR/ralph-monitor.sh connect
}
rmon_web() {
    cd $MONITOR_DIR && PORT=3000 node server.js &
    echo \"Ralph Monitor: http://\$(hostname -I | awk '{print \$1}'):8080\"
}
"

if ! grep -q "Ralph Monitor" ~/.bashrc 2>/dev/null; then
    echo "$ALIASES" >> ~/.bashrc
fi

# 6. Start server
echo "[6/6] Szerver indítása..."
cd "$MONITOR_DIR"
PORT=3000 node server.js &

echo ""
echo "==================================="
echo "  Telepítés kész!"
echo "==================================="
echo ""
echo "Web:  http://\$(hostname -I | awk '{print \$1}'):8080"
echo "CLI:  rmon status"
echo "TUI:  rmontui"
echo ""
echo "Forrás: $MONITOR_DIR"
