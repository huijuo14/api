FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install minimal dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    xvfb \
    python3 \
    libnss3 \
    libatk1.0-0 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxext6 \
    libxi6 \
    libxcursor1 \
    libxss1 \
    libxtst6 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Download FeelingSurf Viewer
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Create startup script with multiple VPN/proxy alternatives
RUN echo '#!/bin/bash\n\
echo "=== Starting FeelingSurf Viewer with IP Rotation === "\n\
\n\
# Function to get current IP\n\
get_ip() {\n\
    curl -s --max-time 10 https://api.ipify.org || echo "Unknown"\n\
}\n\
\n\
echo "🌐 Original IP: $(get_ip)"\n\
\n\
# Alternative 1: Use Tor proxy (if available)\n\
setup_tor() {\n\
    if which tor >/dev/null 2>&1; then\n\
        echo "🔄 Starting Tor proxy..."\n\
        tor > /dev/null 2>&1 &\n\
        sleep 10\n\
        export HTTP_PROXY="socks5://127.0.0.1:9050"\n\
        export HTTPS_PROXY="socks5://127.0.0.1:9050"\n\
        echo "✅ Tor proxy started"\n\
        return 0\n\
    fi\n\
    return 1\n\
}\n\
\n\
# Alternative 2: Use free HTTP proxies\n\
setup_http_proxy() {\n\
    echo "🔄 Trying HTTP proxies..."\n\
    \n\
    # List of free proxies\n\
    PROXIES=(\n\
        "51.158.68.68:8811"   \n\
        "163.172.157.7:80"    \n\
        "51.158.68.133:8811"  \n\
        "163.172.147.94:80"   \n\
    )\n\
    \n\
    for proxy in "${PROXIES[@]}"; do\n\
        echo "Testing proxy: $proxy"\n\
        if curl -s --max-time 10 --proxy "http://$proxy" https://api.ipify.org > /dev/null; then\n\
            export HTTP_PROXY="http://$proxy"\n\
            export HTTPS_PROXY="http://$proxy"\n\
            echo "✅ Using proxy: $proxy"\n\
            echo "🌐 New IP: $(curl -s --max-time 10 --proxy "http://$proxy" https://api.ipify.org)"\n\
            return 0\n\
        fi\n\
    done\n\
    echo "❌ No working HTTP proxies found"\n\
    return 1\n\
}\n\
\n\
# Alternative 3: Download pre-built OpenVPN binary\n\
setup_openvpn_binary() {\n\
    echo "🔄 Downloading pre-built OpenVPN..."\n\
    \n\
    # Try to download static OpenVPN binary\n\
    if wget -q -O /tmp/openvpn-static "https://github.com/OpenVPN/openvpn/raw/master/contrib/openvpn-static/openvpn-static"; then\n\
        chmod +x /tmp/openvpn-static\n\
        \n\
        # Download VPN config\n\
        if wget -q -O /tmp/vpn.ovpn "http://www.vpngate.net/common/openvpn_download.aspx?sid=156"; then\n\
            /tmp/openvpn-static --config /tmp/vpn.ovpn --daemon > /dev/null 2>&1\n\
            sleep 15\n\
            echo "✅ OpenVPN started (static binary)"\n\
            return 0\n\
        fi\n\
    fi\n\
    return 1\n\
}\n\
\n\
# Alternative 4: Use SSH tunnel as proxy\n\
setup_ssh_tunnel() {\n\
    echo "🔄 SSH tunnel not available in this environment"\n\
    return 1\n\
}\n\
\n\
# Alternative 5: Use VPN through Python (if dependencies available)\n\
setup_python_vpn() {\n\
    echo "🔄 Checking for Python VPN options..."\n\
    python3 -c "\n\
import requests\nimport random\nimport time\n\ntry:\n    # Get VPNGate server list\n    response = requests.get(''http://www.vpngate.net/api/iphone/'')\n    lines = response.text.split(''\\n'')\n    \n    servers = []\n    for line in lines[2:]:\n        if line and '','' in line:\n            parts = line.split('','')\n            if len(parts) > 14 and parts[1] != ''*'':\n                servers.append(parts)\n    \n    if servers:\n        # Pick a random server\n        server = random.choice(servers)\n        config = server[14]\n        \n        with open(''/tmp/vpn_config.ovpn'', ''w'') as f:\n            f.write(config)\n        \n        print(f''✅ Downloaded VPN config for {server[1]}'')\n    else:\n        print(''❌ No VPN servers found'')\n        \nexcept Exception as e:\n    print(f''❌ Python VPN setup failed: {e}'')\n"\n    \n    # If config was created, try to use it with any available openvpn\n    if [ -f "/tmp/vpn_config.ovpn" ]; then\n        if which openvpn >/dev/null 2>&1; then\n            openvpn --config /tmp/vpn_config.ovpn --daemon > /dev/null 2>&1\n            sleep 15\n            echo "✅ OpenVPN started via Python"\n            return 0\n        elif [ -f "/tmp/openvpn-static" ]; then\n            /tmp/openvpn-static --config /tmp/vpn_config.ovpn --daemon > /dev/null 2>&1\n            sleep 15\n            echo "✅ OpenVPN started (static + Python)"\n            return 0\n        fi\n    fi\n    return 1\n}\n\
\n\
# Try all methods in order\n\
echo "🔄 Attempting IP rotation methods..."\n\
\n\
setup_openvpn_binary || \\\n\
setup_python_vpn || \\\n\
setup_tor || \\\n\
setup_http_proxy || \\\n\
echo "⚠️  No IP rotation method succeeded, continuing with original IP"\n\
\n\
echo "🌐 Final IP: $(get_ip)"\n\
echo "============================================="\n\
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
    # Try with different approaches if proxy is set\n\
    if [ -n "$HTTP_PROXY" ]; then\n\
        echo "Using proxy: $HTTP_PROXY"\n\
    fi\n\
    \n\
    timeout 4h ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage --disable-gpu 2>&1\n\
    EXIT_CODE=$?\n\
    \n\
    if [ $EXIT_CODE -eq 124 ]; then\n\
        echo "🕒 Session timed out after 4 hours, restarting..."\n\
    else\n\
        echo "🔄 Viewer exited with code $EXIT_CODE, restarting in 30 seconds..."\n\
        sleep 30\n\
    fi\n\
    \n\
    # Small delay before restart\n\
    sleep 5\n\
done' > /app/start.sh && chmod +x /app/start.sh

# Create status page
RUN echo '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>FeelingSurf Viewer</title>\n\
    <meta http-equiv="refresh" content="20">\n\
    <style>\n\
        body { font-family: Arial, sans-serif; margin: 40px; background: #f0f2f5; }\n\
        .container { background: white; padding: 30px; border-radius: 15px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); max-width: 600px; margin: 0 auto; }\n\
        .status { color: #28a745; font-size: 24px; margin-bottom: 20px; font-weight: bold; }\n\
        .info { color: #555; line-height: 1.8; }\n\
        .badge { background: #e7f3ff; color: #0066cc; padding: 4px 12px; border-radius: 12px; font-size: 14px; }\n\
        .log { background: #f8f9fa; padding: 15px; border-radius: 8px; margin-top: 20px; font-family: monospace; font-size: 12px; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <div class="status">🟢 FeelingSurf Viewer Active</div>\n\
        <div class="info">\n\
            <p><strong>Status:</strong> <span class="badge">Running with IP Rotation</span></p>\n\
            <p><strong>User:</strong> alllogin</p>\n\
            <p><strong>Auto-restart:</strong> Every 4 hours</p>\n\
            <p><strong>Features:</strong> Multiple VPN/Proxy methods</p>\n\
            <div class="log">\n\
                System starting...<br>\n\
                Checking IP rotation methods...<br>\n\
                Starting viewer session...\n\
            </div>\n\
        </div>\n\
    </div>\n\
</body>\n\
</html>' > /app/status.html

# Final launch script
RUN echo '#!/bin/bash\n\
# Start web server\n\
cd /app && python3 -m http.server 7860 2>&1 &\n\
\n\
# Start main application\n\
sleep 2\n\
/app/start.sh' > /app/launch.sh && chmod +x /app/launch.sh

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99

EXPOSE 7860

CMD ["/app/launch.sh"]
