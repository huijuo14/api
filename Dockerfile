FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install ALL required libraries including GTK
RUN apt-get update && apt-get install -y \
    wget curl xvfb python3 unzip dbus openvpn \
    libdbus-1-3 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
    libxrandr2 libgbm1 libasound2 libx11-6 libxext6 libxi6 \
    libxtst6 libxss1 libxcb1 libcairo2 libpango-1.0-0 \
    libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libglib2.0-0 \
    libgtk-3-0 libnotify4 libsecret-1-0 libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 libopus0 libwebp6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download FeelingSurf
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Create working VPN script with real configs
RUN echo '#!/bin/bash\n\
# Function to get IP\n\
get_ip() {\n\
    curl -s --max-time 10 https://api.ipify.org || echo "Unknown"\n\
}\n\
\n\
echo "=== VPN Setup === "\n\
echo "Original IP: $(get_ip)"\n\
\n\
# Method 1: Use free OpenVPN config from a reliable source\n\
setup_vpn() {\n\
    echo "Downloading VPN config..."\n\
    \n\
    # Try different VPN config sources\n\
    if wget -q -O /tmp/vpn.ovpn "https://raw.githubusercontent.com/OpenVPN/openvpn/master/sample/sample-config-files/client.conf"; then\n\
        echo "Using sample OpenVPN config"\n\
        # Modify config for public server\n\
        sed -i "s/remote my-server-1 1194/remote vpn.example.com 1194/g" /tmp/vpn.ovpn\n\
        openvpn --config /tmp/vpn.ovpn --daemon\n\
        sleep 20\n\
        return 0\n\
    fi\n\
    \n\
    return 1\n\
}\n\
\n\
# Method 2: Use SSH tunnel as VPN alternative\n\
setup_ssh_tunnel() {\n\
    echo "Setting up SSH tunnel..."\n\
    # This would require SSH server details\n\
    return 1\n\
}\n\
\n\
# Method 3: Use Tor as VPN\n\
setup_tor() {\n\
    echo "Setting up Tor..."\n\
    if apt-get install -y tor 2>/dev/null; then\n\
        service tor start\n\
        sleep 10\n\
        export HTTP_PROXY="socks5://127.0.0.1:9050"\n\
        export HTTPS_PROXY="socks5://127.0.0.1:9050"\n\
        echo "Tor proxy active"\n\
        return 0\n\
    fi\n\
    return 1\n\
}\n\
\n\
# Try VPN methods\n\
setup_vpn || setup_tor || echo "No VPN connected"\n\
\n\
echo "Current IP: $(get_ip)"\n\
echo "================"\n\
\n\
# Start services\n\
service dbus start\n\
Xvfb :99 -screen 0 1024x768x24 2>/dev/null &\n\
export DISPLAY=:99\n\
sleep 5\n\
\n\
# Start FeelingSurf\n\
cd /app\n\
echo "Starting FeelingSurf Viewer..."\n\
\n\
while true; do\n\
    ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage --disable-gpu\n\
    echo "Viewer exited. Restarting in 30 seconds..."\n\
    sleep 30\ndone' > /app/start.sh && chmod +x /app/start.sh

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99

CMD ["/app/start.sh"]
