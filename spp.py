#!/usr/bin/env python3
"""
SimplePOSPrint (SPP.py)
Thermal receipt printer bridge for browser POS with image/logo support.
(c) 2025 Michael Jones (The Ace Of Vapez) & ChatGPT (OpenAI)
License: MIT

Features:
- REST API for direct print from browser extensions.
- Receives text or PNG (image) receipts.
- Auto-generates config.json and repairs device paths.
- Logo upload (logo.png).
- Self-healing: re-checks printer device, avoids staff intervention.
- Modular and ready for .deb/systemd packaging.
"""

from flask import Flask, request, send_from_directory, jsonify
from flask_cors import CORS
from PIL import Image
import os
import json
import base64
import re
from io import BytesIO

# --- App Setup ---
app = Flask(__name__)
CORS(app)

# --- Constants ---
CONFIG_PATH = "config.json"
LOGO_PATH = "logo.png"
DEFAULT_CONFIG = {
    "printer_device": "/dev/usb/lp0",
    "text_width": 42,
    "bitmap_width": 576,
    "prepend_logo": True
}

# --- Config Functions ---
def load_config():
    if not os.path.exists(CONFIG_PATH):
        save_config(DEFAULT_CONFIG)
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

def save_config(config):
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f, indent=4)

# --- Printer Helper ---
def send_to_printer(printer_path, data):
    # Try to auto-heal device path if missing
    if not os.path.exists(printer_path):
        # Try to re-trigger device
        try:
            os.system("sudo udevadm trigger")
        except Exception:
            pass
    # Try again (after udevadm)
    if not os.path.exists(printer_path):
        return False, f"Printer device {printer_path} does not exist. Check printer cable/power."
    try:
        with open(printer_path, "wb") as f:
            f.write(data)
        return True, "Printed successfully"
    except Exception as e:
        return False, str(e)

# --- Logo Printing ---
def print_logo(printer_path, config):
    if os.path.exists(LOGO_PATH):
        width_px = config.get("bitmap_width", 576)
        with open(LOGO_PATH, "rb") as f:
            img = Image.open(f).convert("1")
            new_height = int(img.height * (width_px / img.width))
            img = img.resize((width_px, new_height))
            width_bytes = (img.width + 7) // 8
            height = img.height
            raster_data = b"\x1d\x76\x30\x00"
            raster_data += bytes([width_bytes % 256, width_bytes // 256])
            raster_data += bytes([height % 256, height // 256])
            raster_data += img.tobytes()
            raster_data += b"\n" * 2
            send_to_printer(printer_path, raster_data)

# --- REST Endpoints ---

@app.route("/")
def index():
    return send_from_directory(".", "index.html")

@app.route("/logo", methods=["POST", "GET"])
def logo():
    if request.method == "POST":
        if 'file' not in request.files:
            return jsonify({"status": "error", "message": "No file uploaded"}), 400
        file = request.files['file']
        if not file.filename.lower().endswith(".png"):
            return jsonify({"status": "error", "message": "Logo must be a PNG file"}), 400
        file.save(LOGO_PATH)
        return jsonify({"status": "success"})
    else:
        if not os.path.exists(LOGO_PATH):
            return jsonify({"status": "none"})
        with open(LOGO_PATH, "rb") as f:
            b64 = base64.b64encode(f.read()).decode("ascii")
        return jsonify({"status": "ok", "data": "data:image/png;base64," + b64})

@app.route("/config", methods=["GET", "POST"])
def config():
    if request.method == "GET":
        return jsonify(load_config())
    config = request.json
    save_config(config)
    return jsonify({"status": "saved"})

@app.route("/printers")
def printers():
    devices = []
    for path in ["/dev/usb", "/dev"]:
        try:
            for f in os.listdir(path):
                if f.startswith("lp"):
                    devices.append(os.path.join(path, f))
        except Exception:
            pass
    return jsonify({"devices": devices})

@app.route("/print", methods=["POST"])
def print_data():
    config = load_config()
    printer_path = config.get("printer_device", "/dev/usb/lp0")
    payload = request.json

    if not payload or "type" not in payload:
        return jsonify({"status": "error", "message": "Missing type"}), 400

    try:
        if payload["type"] == "text":
            # Prepend logo (if configured)
            if config.get("prepend_logo", False) and os.path.exists(LOGO_PATH):
                print_logo(printer_path, config)
            text = payload.get("data", "") + "\n\n"
            text = text.replace('\xa0', ' ').replace('\u2217', '*')
            text = re.sub(r'[^\x20-\x7E\n]', '', text)
            width = config.get("text_width", 42)
            lines = [line[:width] for line in text.splitlines()]
            final_text = "\n".join(lines) + "\n\n"
            data = final_text.encode("ascii", errors="ignore") + b'\x1d\x56\x42\x00'
            success, error = send_to_printer(printer_path, data)
        elif payload["type"] == "image":
            raw = payload.get("data", "")
            decoded = base64.b64decode(raw.split(",")[1])
            image = Image.open(BytesIO(decoded)).convert("1")
            width_px = config.get("bitmap_width", 576)
            image = image.resize((width_px, int(image.height * (width_px / image.width))))
            width_bytes = (image.width + 7) // 8
            height = image.height
            raster_data = b"\x1d\x76\x30\x00"
            raster_data += bytes([width_bytes % 256, width_bytes // 256])
            raster_data += bytes([height % 256, height // 256])
            raster_data += image.tobytes()
            raster_data += b"\n" * 3 + b'\x1d\x56\x42\x00'
            success, error = send_to_printer(printer_path, raster_data)
        else:
            return jsonify({"status": "error", "message": "Unknown type"}), 400

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

    if success:
        return jsonify({"status": "success"})
    else:
        return jsonify({"status": "error", "message": error}), 500

@app.route("/<path:path>")
def static_files(path):
    return send_from_directory(".", path)

if __name__ == "__main__":
    # On first launch, generate config.json if needed
    if not os.path.exists(CONFIG_PATH):
        save_config(DEFAULT_CONFIG)
        print("Generated default config.json.")
    app.run(host="0.0.0.0", port=5000)
