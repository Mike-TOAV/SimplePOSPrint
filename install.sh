#!/bin/bash

set -e

echo "== SimplePOSPrint Installer =="

# --- Install dependencies ---
echo "Checking and installing dependencies..."

PKGS="python3 python3-pip python3-venv"
for pkg in $PKGS; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "Installing $pkg..."
        sudo apt update
        sudo apt install -y $pkg
    else
        echo "$pkg already installed."
    fi
done

# # Optional: Install pipx
# if ! command -v pipx &>/dev/null; then
#     echo "Installing pipx..."
#     sudo apt install -y pipx
# else
#     echo "pipx already installed."
# fi

# --- Create Python virtual environment ---
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

echo "Activating virtual environment and installing requirements..."
. venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# --- Set up systemd service ---
SERVICE_FILE="/etc/systemd/system/simpleposprint.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "Setting up systemd service..."
    sudo cp simpleposprint.service.example $SERVICE_FILE
    sudo systemctl daemon-reload
    sudo systemctl enable simpleposprint
    sudo systemctl start simpleposprint
    echo "SimplePOSPrint systemd service installed and started."
else
    echo "Systemd service already set up."
    sudo systemctl restart simpleposprint
fi

# --- Printer device permissions ---
PRINTER_DEVICE=$(jq -r '.printer_device // "/dev/usb/lp0"' config.json 2>/dev/null)
if [ ! -e "$PRINTER_DEVICE" ]; then
    echo "Printer device $PRINTER_DEVICE not found. Please connect the printer and restart SimplePOSPrint after plugging it in."
else
    if [ ! -w "$PRINTER_DEVICE" ]; then
        echo "Adding user '$USER' to 'lp' group for printer permissions..."
        sudo usermod -aG lp $USER
        echo "You may need to logout and login again for permissions to take effect."
    else
        echo "Printer device permissions OK."
    fi
fi

echo "== Installation complete =="
echo "To start the service: sudo systemctl start simpleposprint"
echo "To check status: sudo systemctl status simpleposprint"
