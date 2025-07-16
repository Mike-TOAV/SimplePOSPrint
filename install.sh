#!/bin/bash
set -e

echo "== SimplePOSPrint Installer =="

# Install needed OS packages
echo "Checking for required OS packages..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv libjpeg-dev libopenjp2-7

# Create virtual environment if possible
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv || { echo "Could not create venv, using system Python instead."; }
fi

# Activate venv if it exists, otherwise install requirements system-wide
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "Using Python virtual environment."
    PIP_INSTALL="pip install"
else
    echo "Installing dependencies system-wide."
    PIP_INSTALL="sudo pip3 install"
fi

# Install Python requirements
echo "Installing Python dependencies..."
$PIP_INSTALL --upgrade pip
$PIP_INSTALL -r requirements.txt

# Create /opt/SimplePOSPrint if needed
if [ "$PWD" != "/opt/SimplePOSPrint" ]; then
    echo "Copying SimplePOSPrint files to /opt/SimplePOSPrint..."
    sudo mkdir -p /opt/SimplePOSPrint
    sudo cp -R . /opt/SimplePOSPrint
    cd /opt/SimplePOSPrint
fi

# Make sure service file is in place
echo "Copying systemd service file..."
sudo cp simpleposprint.service /etc/systemd/system/simpleposprint.service

# Set permissions for scripts and web files (optional, but helps non-tech staff)
chmod +x *.sh

# Generate a config.json if missing
if [ ! -f "config.json" ]; then
    echo "Generating initial config.json..."
    cat > config.json <<EOF
{
    "printer_device": "/dev/usb/lp0",
    "text_width": 42,
    "bitmap_width": 576,
    "prepend_logo": true
}
EOF
fi

# Enable and start service
echo "Enabling and starting SimplePOSPrint service..."
sudo systemctl daemon-reload
sudo systemctl enable simpleposprint.service
sudo systemctl restart simpleposprint.service

echo "All done! SimplePOSPrint is now running as a service."
echo "Access it via http://localhost:5000 in your web browser."
echo "If you update the code, just rerun this installer."
