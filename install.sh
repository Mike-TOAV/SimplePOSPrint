#!/bin/bash

set -e

echo "== SimplePOSPrint Installer =="

# 1. System prerequisites
sudo apt update
sudo apt install -y python3 python3-pip

# 2. Python dependencies (latest, system-wide)
pip3 install --upgrade flask flask_cors pillow

# 3. Deploy app files to /opt/simpleposprint
sudo mkdir -p /opt/simpleposprint/static
sudo cp -r ./* /opt/simpleposprint/
sudo chown -R $USER:lp /opt/simpleposprint

# 4. Printer device permissions (lp group access)
sudo usermod -aG lp $USER
sudo chown $USER:lp /dev/usb/lp* 2>/dev/null || true

# 5. Generate default config.json if missing
if [ ! -f /opt/simpleposprint/config.json ]; then
  cat > /opt/simpleposprint/config.json <<EOF
{
  "printer_device": "/dev/usb/lp0",
  "text_width": 42,
  "bitmap_width": 600,
  "prepend_logo": true
}
EOF
fi

# 6. (Optional but recommended) Systemd service
sudo tee /etc/systemd/system/simpleposprint.service > /dev/null <<EOF
[Unit]
Description=SimplePOSPrint Thermal Printer Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/simpleposprint
ExecStart=/usr/bin/python3 /opt/simpleposprint/SPP.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable simpleposprint

echo
echo "== Installation Complete =="
echo "You can start the service now with: sudo systemctl start simpleposprint"
echo "Then access the web UI at: http://localhost:5000/"
echo
