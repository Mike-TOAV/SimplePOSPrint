# SimplePOSPrint
A solution for those with a thermal receipt printer and linux, this software and accompanying chrome plugins allow you to bypass cups, and have your web based POS software print receipts directly to the printer. (This software is very early in development, please feel free to fork it and improve upon it)

## Credits

- Project idea, testing & deployment: Michael Jones (The Ace Of Vapez)
- Code and AI assistance: ChatGPT (OpenAI), 2024–2025

# SimplePOSPrint
# (c) 2025 Michael Jones / The Ace Of Vapez & ChatGPT (OpenAI)
# Licensed under the MIT License

I hope this can become heavily useful for those IT Admins that are struggling with CUPS and the generic POS80 Thermal printers available today. If you have are able to improve upon this please feel free to and let me know about it: mike@taovdistro.co.uk.

**Hybrid print bridge for cloud POS — send receipts directly from browser to your till’s thermal printer!**

- Supports text and image receipts
- Easily upload/change your shop logo
- Modular and self-healing
- Chrome extension included

## Quick Start

1. `python3 -m pip install flask flask-cors pillow`
2. `python3 SPP.py`
3. Open http://localhost:5000 in browser to configure
