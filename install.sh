#!/bin/bash
# SimplePOSPrint install script
# Installs dependencies, sets up systemd service

set -e

echo "Installing required Python packages..."
pip3 install flask flask-cors pillow

echo "Checking for systemd service setup..."
SERVICE="system/simpleposprint.service"
TARGET="/etc/systemd/system/simpleposprint.service"
if [ -f "$SERVICE" ]; then
    sudo cp "$SERVICE" "$TARGET"
    sudo systemctl daemon-reload
    sudo systemctl enable --now simpleposprint
    echo "Service installed and started!"
else
    echo "systemd service file not found, skipping service setup."
fi

echo "Done! Run with: python3 SPP.py"
