FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (minimal approach)
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    xvfb \
    python3 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Download and install OpenVPN static binary (no apt required)
RUN wget -q https://build.openvpn.net/downloads/releases/openvpn-2.5.8.tar.gz && \
    tar -xzf openvpn-2.5.8.tar.gz && \
    cd openvpn-2.5.8 && \
    ./configure && make && make install && \
    cd .. && rm -rf openvpn-2.5.8*

# Set working directory
WORKDIR /app

# Download FeelingSurf Viewer
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Create startup script with VPN integration
RUN echo '#!/bin/bash\n\
echo "=== Starting FeelingSurf Viewer with VPN === "\n\
\n\
# Function to get current IP\n\
get_ip() {\n\
    curl -s https://api.ipify.org\n\
}\n\
\n\
echo "🌐 Original IP: $(get_ip)"\n\
\n\
# Try to setup VPN (will continue without if fails)\n\
setup_vpn() {\n\
    echo "🔄 Attempting to connect VPN..."\n\
    \n\
    # Download VPN config from VPNGate\n\
    if wget -q -O /tmp/vpn.ovpn "http://www.vpngate.net/common/openvpn_download.aspx?sid=156"; then\n\
        echo "✅ Downloaded VPN config"\n\
        \n\
        # Start OpenVPN in background\n\
        openvpn --config /tmp/vpn.ovpn --daemon --auth-nocache --pull-filter ignore "route-ipv6" --pull-filter ignore "ifconfig-ipv6" \n\
        \n\
        # Wait for VPN connection\n\
        echo "⏳ Waiting for VPN connection..."\n\
        sleep 15\n\
        \n\
        # Check if VPN changed IP\n\
        NEW_IP=$(get_ip)\n\
        if [ "$NEW_IP" != "$(get_ip)" ]; then\n\
            echo "✅ VPN Connected - New IP: $NEW_IP"\n\
        else\n\
            echo "⚠️  VPN may not have connected, continuing..."\n\
        fi\n\
    else\n\
        echo "❌ Failed to download VPN config, continuing without VPN"\n\
    fi\n\
}\n\
\n\
# Setup VPN\n\
setup_vpn\n\
\n\
# Start Xvfb\n\
echo "🖥️  Starting virtual display..."\n\
Xvfb :99 -screen 0 1024x768x24 2>/dev/null &\n\
export DISPLAY=:99\n\
sleep 2\n\
\n\
# Start FeelingSurf Viewer\n\
echo "🚀 Starting FeelingSurf Viewer..."\n\
cd /app\n\
\n\
# Run viewer with timeout and restart on failure\n\
while true; do\n\
    echo "$(date): Starting viewer session..."\n\
    timeout 6h ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage 2>&1\n\
    EXIT_CODE=$?\n\
    \n\
    if [ $EXIT_CODE -eq 124 ]; then\n\
        echo "🕒 Session timed out after 6 hours, restarting..."\n\
    else\n\
        echo "🔄 Viewer exited with code $EXIT_CODE, restarting in 30 seconds..."\n\
        sleep 30\n\
    fi\n\
    \n\
    # Small delay before restart\n\
    sleep 5\n\
done' > /app/start.sh && chmod +x /app/start.sh

# Create simple status page
RUN echo '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>FeelingSurf Viewer</title>\n\
    <meta http-equiv="refresh" content="15">\n\
    <style>\n\
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }\n\
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }\n\
        .status { color: #28a745; font-size: 24px; margin-bottom: 20px; }\n\
        .info { color: #555; line-height: 1.6; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <div class="status">✅ FeelingSurf Viewer Running</div>\n\
        <div class="info">\n\
            <p><strong>Status:</strong> Active with VPN</p>\n\
            <p><strong>User:</strong> alllogin</p>\n\
            <p><strong>Mode:</strong> Automated Browser</p>\n\
            <p><strong>Auto-restart:</strong> Enabled (6h cycles)</p>\n\
            <p><em>This page refreshes every 15 seconds</em></p>\n\
        </div>\n\
    </div>\n\
</body>\n\
</html>' > /app/status.html

# Start web server in background and main app
RUN echo '#!/bin/bash\n\
# Start web server for status page\n\
cd /app && python3 -m http.server 7860 > /tmp/webserver.log 2>&1 &\n\
\n\
# Wait a moment for web server to start\n\
sleep 2\n\
\n\
# Start the main application\n\
exec /app/start.sh' > /app/launch.sh && chmod +x /app/launch.sh

# Set environment variables
ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99

EXPOSE 7860

CMD ["/app/launch.sh"]
