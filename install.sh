#!/bin/bash

echo "== SimplePOSPrint Installer =="

# Always run from the repo root
cd "$(dirname "$0")"

# System requirements
REQUIRED_APT_PACKAGES="python3 python3-pip python3-venv libjpeg-dev libfreetype6-dev"

# Check and install system dependencies
echo "-- Checking system dependencies (apt)..."
if [ "$(id -u)" -ne 0 ]; then
    echo "You may be prompted for your password to install system packages."
    sudo apt update
    sudo apt install -y $REQUIRED_APT_PACKAGES
else
    apt update
    apt install -y $REQUIRED_APT_PACKAGES
fi

# Create Python venv if not present
if [ ! -d venv ]; then
    echo "-- Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate venv and upgrade pip
echo "-- Activating virtual environment and installing dependencies..."
source venv/bin/activate
python3 -m pip install --upgrade pip

# Install Python dependencies (inside venv)
if [ -f requirements.txt ]; then
    pip install -r requirements.txt
else
    pip install flask flask_cors pillow
fi

# Prepopulate config.json if it does not exist
if [ ! -f config.json ]; then
    echo "-- Creating default config.json"
    cat > config.json <<EOF
{
    "printer_device": "/dev/usb/lp0",
    "text_width": 42,
    "bitmap_width": 576,
    "prepend_logo": false
}
EOF
fi

echo "-- Installation complete."
echo
echo "To run SimplePOSPrint, activate the venv and start:"
echo "  source venv/bin/activate"
echo "  python3 SPP.py"
echo

# Offer to install as a service (if systemd service file is present)
if [ -f simpleposprint.service ]; then
    if [ "$(id -u)" -ne 0 ]; then
        echo "To install as a systemd service, run:"
        echo "  sudo cp simpleposprint.service /etc/systemd/system/"
        echo "  sudo systemctl daemon-reload"
        echo "  sudo systemctl enable --now simpleposprint"
    else
        cp simpleposprint.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl enable --now simpleposprint
        echo "SimplePOSPrint systemd service installed and started!"
    fi
fi
