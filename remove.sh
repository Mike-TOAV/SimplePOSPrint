#!/bin/bash

#!/bin/bash
echo "== SimplePOSPrint Uninstaller =="
SERVICE="simpleposprint"
INSTALL_DIR="/opt/SimplePOSPrint"
SERVICE_FILE="/etc/systemd/system/simpleposprint.service"

sudo systemctl stop $SERVICE || true
sudo systemctl disable $SERVICE || true
sudo rm -f $SERVICE_FILE
sudo systemctl daemon-reload

if [ -d "$INSTALL_DIR" ]; then
    sudo rm -rf "$INSTALL_DIR"
fi
if [ -d "venv" ]; then
    rm -rf venv
fi

echo "SimplePOSPrint has been removed."
