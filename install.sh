#!/bin/bash
set -e

echo "== SimplePOSPrint Installer =="

# Required system packages
REQUIRED_PKGS="python3 python3-pip python3-venv libjpeg-dev libopenjp2-7"
for pkg in $REQUIRED_PKGS; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "-- Installing $pkg..."
        sudo apt-get update
        sudo apt-get install -y "$pkg"
    else
        echo "-- $pkg already installed"
    fi
done

# Create and activate Python virtualenv
if [ ! -d "venv" ]; then
    echo "-- Creating virtual environment..."
    python3 -m venv venv
fi
source venv/bin/activate

echo "-- Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Prepare /opt/SimplePOSPrint
sudo mkdir -p /opt/SimplePOSPrint
sudo cp -r ./* /opt/SimplePOSPrint/
sudo chmod -R 755 /opt/SimplePOSPrint

# Ensure spp.py is executable
sudo chmod +x /opt/SimplePOSPrint/spp.py

# Install the service file
sudo cp simpleposprint.service /etc/systemd/system/simpleposprint.service

# Reload and enable the service
sudo systemctl daemon-reload
sudo systemctl enable simpleposprint.service
sudo systemctl restart simpleposprint.service

# Print the status
echo ""
echo "== SimplePOSPrint Service Status =="
sudo systemctl status simpleposprint.service --no-pager

echo ""
echo "== Install complete! =="
echo "Access the config page at: http://localhost:5000/config.html"
