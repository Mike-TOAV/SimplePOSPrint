#!/bin/bash
set -e

echo "== SimplePOSPrint Installer =="

PROJECT_DIR="$(pwd)"
SERVICE_FILE="/etc/systemd/system/simpleposprint.service"
VENV_DIR="$PROJECT_DIR/venv"
PYTHON="python3"

# 1. Check for Python 3 and pip
if ! command -v $PYTHON >/dev/null; then
    echo "Python 3 not found. Please install python3."
    exit 1
fi
if ! command -v pip3 >/dev/null; then
    echo "pip3 not found. Please install python3-pip."
    exit 1
fi

# 2. Create virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    $PYTHON -m venv "$VENV_DIR"
fi

# 3. Install requirements
echo "Installing Python requirements into venv..."
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r requirements.txt

# 4. Check/add user to lp group for USB printer access
USER_TO_USE="${SUDO_USER:-$USER}"
if id "$USER_TO_USE" | grep -q " lp)"; then
    echo "User $USER_TO_USE is already in lp group."
else
    echo "Adding $USER_TO_USE to lp group (may need logout/login)..."
    sudo usermod -aG lp "$USER_TO_USE"
fi

# 5. Generate systemd service file
echo "Creating/updating systemd service file..."
cat <<EOF | sudo tee $SERVICE_FILE >/dev/null
[Unit]
Description=SimplePOSPrint thermal printer server
After=network.target

[Service]
Type=simple
User=$USER_TO_USE
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/venv/bin/python $PROJECT_DIR/SPP.py
Restart=always
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 6. Reload, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable simpleposprint
sudo systemctl restart simpleposprint

echo "== SimplePOSPrint installed and started! =="
echo "You can check status with: sudo systemctl status simpleposprint"
echo "If you just added yourself to lp group, a logout/login may be required for permissions."
