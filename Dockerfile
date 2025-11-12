FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install ALL required libraries
RUN apt-get update && apt-get install -y \
    wget curl xvfb python3 python3-pip unzip dbus openvpn \
    libdbus-1-3 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
    libxrandr2 libgbm1 libasound2 libx11-6 libxext6 libxi6 \
    libxtst6 libxss1 libxcb1 libcairo2 libpango-1.0-0 \
    libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libglib2.0-0 \
    libgtk-3-0 libnotify4 \
    && rm -rf /var/lib/apt/lists/*

# Install Python requests
RUN pip3 install requests

WORKDIR /app

# Download FeelingSurf
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Create Python script to find working VPN
RUN echo 'import requests\nimport base64\nimport random\n\n# Get VPNGate server list\nurl = "http://www.vpngate.net/api/iphone/"\ntry:\n    response = requests.get(url, timeout=10)\n    lines = response.text.split("\\n")\n    \n    # Find working configs\n    for line in lines[2:]:\n        if line and "," in line:\n            parts = line.split(",")\n            if len(parts) > 14 and parts[1] != "*" and parts[14]:\n                # This is base64 encoded OpenVPN config\n                config_b64 = parts[14]\n                try:\n                    config = base64.b64decode(config_b64).decode("utf-8")\n                    if "remote " in config and "cipher " in config:\n                        with open("/tmp/vpn.ovpn", "w") as f:\n                            f.write(config)\n                        print(f"Found working VPN: {parts[1]}")\n                        exit(0)\n                except:\n                    continue\n    print("No working VPN config found")\n    exit(1)\nexcept Exception as e:\n    print(f"Error: {e}")\n    exit(1)' > /app/find_vpn.py

# Create startup script
RUN echo '#!/bin/bash\n\
# Find working VPN\n\
echo "Finding working VPN server..."\n\
python3 /app/find_vpn.py\n\
\n\
# Start VPN if config found\n\
if [ -f "/tmp/vpn.ovpn" ]; then\n\
    echo "Starting VPN..."\n\
    openvpn --config /tmp/vpn.ovpn --daemon\n\
    sleep 20\n\
    echo "VPN connected"\n\
else\n\
    echo "No VPN config found, continuing without VPN"\n\
fi\n\
\n\
# Start services\n\
service dbus start\n\
Xvfb :99 -screen 0 1024x768x24 2>/dev/null &\n\
export DISPLAY=:99\n\
sleep 5\n\
\n\
# Start FeelingSurf\n\
cd /app\n\
while true; do\n\
    ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage\n\
    sleep 30\ndone' > /app/start.sh && chmod +x /app/start.sh

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99

CMD ["/app/start.sh"]
