#!/bin/bash

echo "== SimplePOSPrint Uninstaller =="

# Confirm directory (be careful!)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Stop systemd service if present
if systemctl --user status simpleposprint.service >/dev/null 2>&1; then
    echo "Stopping user systemd service..."
    systemctl --user stop simpleposprint.service
    systemctl --user disable simpleposprint.service
elif sudo systemctl status simpleposprint.service >/dev/null 2>&1; then
    echo "Stopping system systemd service..."
    sudo systemctl stop simpleposprint.service
    sudo systemctl disable simpleposprint.service
fi

# Remove systemd service files (both user and system-wide)
if [ -f ~/.config/systemd/user/simpleposprint.service ]; then
    echo "Removing user systemd service file..."
    rm ~/.config/systemd/user/simpleposprint.service
fi
if [ -f /etc/systemd/system/simpleposprint.service ]; then
    echo "Removing system-wide service file (sudo required)..."
    sudo rm /etc/systemd/system/simpleposprint.service
fi

# Remove venv
if [ -d "$DIR/venv" ]; then
    echo "Removing virtual environment..."
    rm -rf "$DIR/venv"
fi

# Remove config and logo
rm -f "$DIR/config.json"
rm -f "$DIR/logo.png"

# Remove logs (if you created a logs dir)
rm -rf "$DIR/logs"

# Optional: Remove the project files
read -p "Do you want to delete all SimplePOSPrint source files in $DIR? (y/N): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Deleting all source files..."
    cd "$DIR/.."
    rm -rf "$DIR"
fi

echo "Done."
