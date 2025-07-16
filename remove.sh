#!/bin/bash
echo "== SimplePOSPrint Uninstaller =="

# 1. Stop and disable the service
echo "Stopping SimplePOSPrint service..."
sudo systemctl stop simpleposprint.service 2>/dev/null
sudo systemctl disable simpleposprint.service 2>/dev/null

# 2. Remove systemd unit
if [ -f /etc/systemd/system/simpleposprint.service ]; then
    echo "Removing systemd service..."
    sudo rm /etc/systemd/system/simpleposprint.service
    sudo systemctl daemon-reload
fi

# 3. Remove installed files
if [ -d /opt/SimplePOSPrint ]; then
    echo "Removing /opt/SimplePOSPrint..."
    sudo rm -rf /opt/SimplePOSPrint
fi

# 4. Remove virtual environment from this folder if present
if [ -d ./venv ]; then
    echo "Removing virtualenv in $(pwd)..."
    rm -rf ./venv
fi

# 5. Optionally remove the source folder
read -p "Do you want to delete this SimplePOSPrint source folder ($(pwd))? [y/N]: " REMOVE_SRC
if [[ "$REMOVE_SRC" =~ ^[Yy]$ ]]; then
    cd ..
    rm -rf ./SimplePOSPrint
    echo "Removed source folder."
else
    echo "Source folder left intact."
fi

echo ""
echo "SimplePOSPrint files and service removed."

# 6. Offer to remove Python3 & dependencies (advanced/dangerous!)
echo
echo "!! WARNING: Removing python3/python3-venv/python3-pip can BREAK your system if other tools use them!"
read -p "Remove Python3 and all dependencies? (NOT RECOMMENDED unless you know what you are doing) [y/N]: " REMOVE_PY
if [[ "$REMOVE_PY" =~ ^[Yy]$ ]]; then
    echo "Uninstalling python3, python3-venv, python3-pip..."
    sudo apt remove --purge -y python3 python3-venv python3-pip
    sudo apt autoremove -y
    echo "Python3 and related packages removed."
else
    echo "Python left installed."
fi

echo ""
echo "== Uninstall complete =="
