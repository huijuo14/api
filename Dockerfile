FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install libraries + OpenVPN
RUN apt-get update && apt-get install -y \
    wget curl xvfb python3 unzip dbus openvpn \
    libdbus-1-3 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
    libxrandr2 libgbm1 libasound2 libx11-6 libxext6 libxi6 \
    libxtst6 libxss1 libxcb1 libcairo2 libpango-1.0-0 \
    libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download FeelingSurf
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# VPN startup script
RUN echo '#!/bin/bash\n\
# Start VPN first\n\
echo "Setting up VPN..."\n\
wget -q -O /tmp/vpn.ovpn "https://www.vpngate.net/common/openvpn_download.aspx?sid=161"\n\
if [ -f /tmp/vpn.ovpn ]; then\n\
    openvpn --config /tmp/vpn.ovpn --daemon\n\
    sleep 15\n\
    echo "VPN connected"\n\
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
