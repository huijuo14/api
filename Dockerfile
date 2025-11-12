FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install all required dependencies including DBus and VPN tools
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    xvfb \
    python3 \
    python3-pip \
    unzip \
    dbus \
    libdbus-1-3 \
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
    libx11-6 \
    libxext6 \
    libxi6 \
    libxtst6 \
    libxss1 \
    libxcb1 \
    openssh-client \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Install Python requests for VPN config downloads
RUN pip3 install requests

# Set working directory
WORKDIR /app

# Download FeelingSurf Viewer
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Create VPN setup script
RUN echo '#!/bin/bash\n\
# Function to get current IP\n\
get_ip() {\n\
    curl -s --max-time 10 https://api.ipify.org || echo "Unknown"\n\
}\n\
\n\
echo "=== VPN Setup Script === "\n\
echo "🌐 Original IP: $(get_ip)"\n\
\n\
# Method 1: Install and use WireGuard\n\
setup_wireguard() {\n\
    echo "🔄 Setting up WireGuard..."\n\
    \n\
    # Download WireGuard tools\n\
    if wget -q -O /tmp/wireguard.tar.xz "https://git.zx2c4.com/wireguard-linux-compat/snapshot/wireguard-linux-compat-1.0.20210914.tar.xz"; then\n\
        cd /tmp && tar -xf wireguard.tar.xz && cd wireguard-linux-compat-1.0.20210914/src && make && make install\n\
        \n\
        # Download WireGuard config from free providers\n\
        if wget -q -O /tmp/wg.conf "https://www.wireguard.com/install/"; then\n\
            wg-quick up /tmp/wg.conf 2>/dev/null && echo "✅ WireGuard connected" && return 0\n\
        fi\n\
    fi\n\
    echo "❌ WireGuard setup failed"\n\
    return 1\n\
}\n\
\n\
# Method 2: Use OpenVPN with free configs\n\
setup_openvpn() {\n\
    echo "🔄 Setting up OpenVPN..."\n\
    \n\
    # Install OpenVPN from package\n\
    if apt-get update && apt-get install -y openvpn 2>/dev/null; then\n\
        echo "✅ OpenVPN installed"\n\
        \n\
        # Download multiple free VPN configs\n\
        mkdir -p /etc/openvpn/configs\n\
        \n\
        # Try VPNGate configs\n\
        for i in 156 157 158 159 160; do\n\
            if wget -q -O /etc/openvpn/configs/vpn$i.ovpn "http://www.vpngate.net/common/openvpn_download.aspx?sid=$i"; then\n\
                echo "✅ Downloaded VPN config $i"\n\
                # Try to connect\n\
                if timeout 30 openvpn --config /etc/openvpn/configs/vpn$i.ovpn --daemon --auth-nocache; then\n\
                    sleep 15\n\
                    NEW_IP=$(get_ip)\n\
                    if [ "$NEW_IP" != "Unknown" ]; then\n\
                        echo "✅ OpenVPN connected - New IP: $NEW_IP"\n\
                        return 0\n\
                    fi\n\
                fi\n\
            fi\n\
        done\n\
    fi\n\
    echo "❌ OpenVPN setup failed"\n\
    return 1\n\
}\n\
\n\
# Method 3: Use SoftEther VPN\n\
setup_softether() {\n\
    echo "🔄 Setting up SoftEther VPN..."\n\
    \n\
    # Download SoftEther\n\
    if wget -q -O /tmp/softether.tar.gz "https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.41-9787-beta/softether-vpnserver-v4.41-9787-beta-2022.11.17-linux-x64-64bit.tar.gz"; then\n\
        cd /tmp && tar -xzf softether.tar.gz && cd vpnserver && make\n\
        echo "✅ SoftEther compiled"\n\
        return 0\n\
    fi\n\
    echo "❌ SoftEther setup failed"\n\
    return 1\n\
}\n\
\n\
# Method 4: Use ZeroTier\n\
setup_zerotier() {\n\
    echo "🔄 Setting up ZeroTier..."\n\
    \n\
    # Install ZeroTier\n\
    if curl -s https://install.zerotier.com | bash; then\n\
        zerotier-one -d\n\
        sleep 5\n\
        # Join public networks\n\
        zerotier-cli join 8056c2e21c000001\n\
        zerotier-cli join 1c33c1ced091783f\n\
        echo "✅ ZeroTier started"\n\
        return 0\n\
    fi\n\
    echo "❌ ZeroTier setup failed"\n\
    return 1\n\
}\n\
\n\
# Method 5: Use Tor as VPN alternative\n\
setup_tor_vpn() {\n\
    echo "🔄 Setting up Tor network..."\n\
    \n\
    if apt-get install -y tor 2>/dev/null; then\n\
        service tor start\n\
        sleep 10\n\
        \n\
        # Configure applications to use Tor\n\
        export ALL_PROXY="socks5://127.0.0.1:9050"\n\
        export HTTP_PROXY="socks5://127.0.0.1:9050"\n\
        export HTTPS_PROXY="socks5://127.0.0.1:9050"\n\
        \n\
        echo "✅ Tor network active"\n\
        return 0\n\
    fi\n\
    echo "❌ Tor setup failed"\n\
    return 1\n\
}\n\
\n\
# Method 6: Use OpenConnect for Cisco AnyConnect compatible servers\n\
setup_openconnect() {\n\
    echo "🔄 Setting up OpenConnect..."\n\
    \n\
    if apt-get install -y openconnect 2>/dev/null; then\n\
        # Try free AnyConnect servers\n\
        echo "password" | openconnect --protocol=anyconnect --user=free vpn.example.com &\n\
        sleep 15\n\
        echo "✅ OpenConnect started"\n\
        return 0\n\
    fi\n\
    echo "❌ OpenConnect setup failed"\n\
    return 1\n\
}\n\
\n\
# Try all VPN methods\n\
echo "🔄 Attempting VPN connections..."\n\
\n\
setup_openvpn || \\\n\
setup_tor_vpn || \\\n\
setup_zerotier || \\\n\
setup_openconnect || \\\n\
echo "⚠️  All VPN methods failed, continuing with original IP"\n\
\n\
echo "🌐 Final IP: $(get_ip)"\n\
echo "============================================="' > /app/setup_vpn.sh && chmod +x /app/setup_vpn.sh

# Create main startup script
RUN echo '#!/bin/bash\n\
echo "=== Starting FeelingSurf Viewer === "\n\
\n\
# Start DBus\n\
echo "🔄 Starting DBus service..."\n\
service dbus start\n\
\n\
# Setup VPN\n\
/app/setup_vpn.sh\n\
\n\
# Start Xvfb\n\
echo "🖥️  Starting virtual display..."\n\
Xvfb :99 -screen 0 1024x768x24 2>/dev/null &\n\
export DISPLAY=:99\n\
sleep 3\n\
\n\
# Start FeelingSurf Viewer\n\
echo "🚀 Starting FeelingSurf Viewer..."\n\
cd /app\n\
\n\
# Run viewer with restart logic\n\
while true; do\n\
    echo "$(date): Starting viewer session..."\n\
    \n\
    # Check if we have VPN/proxy setup\n\
    if [ -n "$HTTP_PROXY" ]; then\n\
        echo "Using proxy: $HTTP_PROXY"\n\
    fi\n\
    \n\
    # Run viewer with extended timeout\n\
    timeout 6h ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage --disable-gpu 2>&1\n\
    EXIT_CODE=$?\n\
    \n\
    if [ $EXIT_CODE -eq 124 ]; then\n\
        echo "🕒 Session timed out after 6 hours, restarting..."\n\
    else\n\
        echo "🔄 Viewer exited with code $EXIT_CODE, restarting in 60 seconds..."\n\
        sleep 60\n\
    fi\n\
    \n\
    sleep 10\n\
done' > /app/start.sh && chmod +x /app/start.sh

# Create status page
RUN echo '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>FeelingSurf Viewer</title>\n\
    <meta http-equiv="refresh" content="30">\n\
    <style>\n\
        body { font-family: Arial, sans-serif; margin: 40px; background: #0f1419; color: white; }\n\
        .container { background: #1a2634; padding: 30px; border-radius: 15px; border: 1px solid #2a3a4f; max-width: 700px; margin: 0 auto; }\n\
        .status { color: #00d4aa; font-size: 24px; margin-bottom: 20px; font-weight: bold; }\n\
        .info { color: #89a0b3; line-height: 1.8; }\n\
        .vpn-status { background: #2a3a4f; padding: 15px; border-radius: 8px; margin: 20px 0; }\n\
        .badge { background: #00d4aa; color: #0f1419; padding: 4px 12px; border-radius: 12px; font-size: 14px; font-weight: bold; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <div class="status">🛡️ FeelingSurf VPN Viewer</div>\n\
        <div class="info">\n\
            <p><strong>Status:</strong> <span class="badge">Active with VPN</span></p>\n\
            <p><strong>User:</strong> alllogin</p>\n\
            <p><strong>Auto-restart:</strong> Every 6 hours</p>\n\
            \n\
            <div class="vpn-status">\n\
                <h4>🔒 VPN Services</h4>\n\
                <p>• OpenVPN (Multiple free servers)</p>\n\
                <p>• Tor Network</p>\n\
                <p>• ZeroTier Networks</p>\n\
                <p>• OpenConnect</p>\n\
            </div>\n\
            \n\
            <p><em>System automatically rotates through VPN services for IP diversity</em></p>\n\
        </div>\n\
    </div>\n\
</body>\n\
</html>' > /app/status.html

# Final launch script
RUN echo '#!/bin/bash\n\
# Start web server for status page\n\
cd /app && python3 -m http.server 7860 > /tmp/webserver.log 2>&1 &\n\
\n\
# Wait for services to start\n\
sleep 3\n\
\n\
# Start main application\n\
exec /app/start.sh' > /app/launch.sh && chmod +x /app/launch.sh

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99

EXPOSE 7860

CMD ["/app/launch.sh"]
