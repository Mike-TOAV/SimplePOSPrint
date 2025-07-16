#!/bin/bash
set -e

echo "== SimplePOSPrint Installer =="

# Define variables
INSTALL_DIR="/opt/SimplePOSPrint"
SERVICE_FILE="/etc/systemd/system/simpleposprint.service"
REPO_DIR="$(pwd)"

# Helper function for sudo check
needs_sudo() {
    [ "$EUID" -ne 0 ]
}

# Clean up previous venv if broken
if [ -d venv ]; then
    echo "Checking for broken venv..."
    if [ ! -f venv/bin/activate ]; then
        echo "Found incomplete venv, removing..."
        rm -rf venv
    fi
fi

# Make sure we are NOT root for Python venv setup
if [ "$EUID" -eq 0 ]; then
    echo "Please do NOT run this script as root! Just use ./install.sh"
    exit 1
fi

# 1. OS dependencies
echo "Checking for required OS packages..."
PKGS="python3 python3-pip python3-venv libjpeg-dev libopenjp2-7"
sudo apt-get update
sudo apt-get install -y $PKGS

# 2. Python venv
if [ ! -d venv ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi
echo "Using Python virtual environment."
. venv/bin/activate

# 3. Python dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# 4. Move/copy files to /opt/SimplePOSPrint
if needs_sudo; then
    echo "Copying SimplePOSPrint files to $INSTALL_DIR..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo rsync -a --delete . "$INSTALL_DIR/"
    sudo chown -R $USER:$USER "$INSTALL_DIR"
else
    echo "Copying files (not using sudo)..."
    mkdir -p "$INSTALL_DIR"
    rsync -a --delete . "$INSTALL_DIR/"
fi

# 5. Install systemd service
echo "Copying systemd service file..."
SERVICE_CONTENT="[Unit]
Description=SimplePOSPrint thermal print server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/SPP.py
Restart=on-failure

[Install]
WantedBy=multi-user.target"

echo "$SERVICE_CONTENT" | sudo tee $SERVICE_FILE > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable --now simpleposprint

echo ""
echo "== SimplePOSPrint installed and running =="
echo "Access: http://localhost:5000 or your server IP."
echo ""
echo "To uninstall, run ./remove.sh"
