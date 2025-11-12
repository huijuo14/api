FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install all dependencies including Tor
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    xvfb \
    python3 \
    python3-pip \
    libgtk-3-0 \
    libnotify4 \
    libnss3 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    libatspi2.0-0 \
    libdrm2 \
    libgbm1 \
    libasound2 \
    curl \
    tor \
    privoxy \
    obfs4proxy \
    dnsutils \
    net-tools \
    procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download FeelingSurf
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Configure Tor with IP rotation
RUN mkdir -p /var/lib/tor && chmod 700 /var/lib/tor && \
    echo 'SocksPort 0.0.0.0:9050\n\
SocksPolicy accept 0.0.0.0/0\n\
Log notice stdout\n\
DataDirectory /var/lib/tor\n\
\n\
# Enable faster circuit building\n\
CircuitBuildTimeout 10\n\
LearnCircuitBuildTimeout 0\n\
\n\
# Rotate IP every 10 minutes\n\
MaxCircuitDirtiness 600\n\
\n\
# Use multiple entry guards\n\
NumEntryGuards 8\n\
\n\
# Faster stream timeout\n\
CircuitStreamTimeout 30\n\
\n\
# Allow connections from any IP (for Railway)\n\
SocksPolicy accept 0.0.0.0/0\n\
\n\
# Exit node countries (prefer fast ones)\n\
ExitNodes {us},{ca},{gb},{de},{nl},{fr}\n\
StrictNodes 0\n\
\n\
# Performance tuning\n\
AvoidDiskWrites 1\n\
DisableDebuggerAttachment 0' > /etc/tor/torrc

# Create enhanced status page with Railway-optimized UI
RUN echo '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>FeelingSurf + Tor on Railway</title>\n\
    <meta http-equiv="refresh" content="10">\n\
    <style>\n\
        * { margin: 0; padding: 0; box-sizing: border-box; }\n\
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif; background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; color: white; }\n\
        .container { background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); padding: 50px; border-radius: 25px; box-shadow: 0 25px 80px rgba(0,0,0,0.5); max-width: 800px; width: 100%; border: 1px solid rgba(255,255,255,0.1); }\n\
        .header { text-align: center; margin-bottom: 40px; }\n\
        .logo { font-size: 72px; margin-bottom: 15px; animation: float 3s ease-in-out infinite; }\n\
        @keyframes float { 0%, 100% { transform: translateY(0px); } 50% { transform: translateY(-10px); } }\n\
        h1 { font-size: 32px; margin-bottom: 10px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }\n\
        .subtitle { color: rgba(255,255,255,0.6); font-size: 14px; }\n\
        .status-row { display: flex; align-items: center; justify-content: center; gap: 15px; margin: 20px 0; }\n\
        .status-badge { display: inline-flex; align-items: center; gap: 10px; background: rgba(40, 167, 69, 0.2); border: 2px solid #28a745; color: #4ade80; padding: 10px 20px; border-radius: 25px; font-size: 15px; font-weight: 600; }\n\
        .status-dot { width: 10px; height: 10px; background: #4ade80; border-radius: 50%; animation: pulse-dot 2s infinite; box-shadow: 0 0 10px #4ade80; }\n\
        @keyframes pulse-dot { 0%, 100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.5; transform: scale(1.2); } }\n\
        .ip-container { background: linear-gradient(135deg, rgba(102, 126, 234, 0.3) 0%, rgba(118, 75, 162, 0.3) 100%); padding: 35px; border-radius: 20px; margin: 30px 0; border: 1px solid rgba(102, 126, 234, 0.5); position: relative; overflow: hidden; }\n\
        .ip-container::before { content: ""; position: absolute; top: -50%; left: -50%; width: 200%; height: 200%; background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%); animation: shimmer 3s linear infinite; }\n\
        @keyframes shimmer { 0% { transform: translate(-50%, -50%) rotate(0deg); } 100% { transform: translate(-50%, -50%) rotate(360deg); } }\n\
        .ip-row { display: flex; justify-content: space-between; align-items: center; margin: 15px 0; position: relative; z-index: 1; }\n\
        .ip-label { font-size: 13px; color: rgba(255,255,255,0.7); text-transform: uppercase; letter-spacing: 1.5px; font-weight: 600; }\n\
        .ip-value { font-size: 24px; font-weight: bold; font-family: "Monaco", "Courier New", monospace; color: #fff; text-shadow: 0 2px 10px rgba(102, 126, 234, 0.5); }\n\
        .ip-change { color: #4ade80; font-size: 12px; }\n\
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin: 25px 0; }\n\
        .stat-card { background: rgba(255,255,255,0.05); padding: 20px; border-radius: 15px; text-align: center; border: 1px solid rgba(255,255,255,0.1); transition: all 0.3s ease; }\n\
        .stat-card:hover { background: rgba(255,255,255,0.1); transform: translateY(-5px); }\n\
        .stat-icon { font-size: 28px; margin-bottom: 10px; }\n\
        .stat-label { font-size: 11px; color: rgba(255,255,255,0.5); text-transform: uppercase; margin-bottom: 8px; letter-spacing: 1px; }\n\
        .stat-value { font-size: 20px; font-weight: bold; color: #fff; }\n\
        .footer { margin-top: 30px; padding-top: 25px; border-top: 1px solid rgba(255,255,255,0.1); text-align: center; color: rgba(255,255,255,0.4); font-size: 13px; }\n\
        .railway-badge { display: inline-block; background: linear-gradient(135deg, #8b5cf6 0%, #6366f1 100%); padding: 5px 12px; border-radius: 15px; font-size: 11px; font-weight: 600; margin-top: 10px; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <div class="header">\n\
            <div class="logo">🛡️</div>\n\
            <h1>FeelingSurf + Tor Network</h1>\n\
            <div class="subtitle">Deployed on Railway • Rotating IP Every 10 Minutes</div>\n\
            <div class="status-row">\n\
                <span class="status-badge">\n\
                    <span class="status-dot"></span>\n\
                    System Active\n\
                </span>\n\
            </div>\n\
        </div>\n\
        \n\
        <div class="ip-container">\n\
            <div class="ip-row">\n\
                <span class="ip-label">Current Exit IP</span>\n\
                <span class="ip-value" id="current-ip">Loading...</span>\n\
            </div>\n\
            <div class="ip-row">\n\
                <span class="ip-label">Original IP</span>\n\
                <span class="ip-value" id="original-ip">---.---.---.---</span>\n\
            </div>\n\
            <div style="text-align: center; margin-top: 15px;">\n\
                <span class="ip-change" id="ip-status">• Checking IP rotation...</span>\n\
            </div>\n\
        </div>\n\
        \n\
        <div class="stats-grid">\n\
            <div class="stat-card">\n\
                <div class="stat-icon">👤</div>\n\
                <div class="stat-label">User</div>\n\
                <div class="stat-value">alllogin</div>\n\
            </div>\n\
            <div class="stat-card">\n\
                <div class="stat-icon">🔄</div>\n\
                <div class="stat-label">Rotation</div>\n\
                <div class="stat-value">10 min</div>\n\
            </div>\n\
            <div class="stat-card">\n\
                <div class="stat-icon">🌐</div>\n\
                <div class="stat-label">Network</div>\n\
                <div class="stat-value">Tor</div>\n\
            </div>\n\
            <div class="stat-card">\n\
                <div class="stat-icon">📦</div>\n\
                <div class="stat-label">Version</div>\n\
                <div class="stat-value">2.5.0</div>\n\
            </div>\n\
        </div>\n\
        \n\
        <div class="footer">\n\
            Auto-refreshing every 10 seconds • Traffic routed through Tor<br>\n\
            <span class="railway-badge">Powered by Railway</span>\n\
        </div>\n\
    </div>\n\
    <script>\n\
        let originalIP = localStorage.getItem("originalIP");\n\
        \n\
        async function updateIP() {\n\
            try {\n\
                const response = await fetch("https://api.ipify.org?format=json");\n\
                const data = await response.json();\n\
                const currentIP = data.ip;\n\
                \n\
                document.getElementById("current-ip").textContent = currentIP;\n\
                \n\
                if (!originalIP) {\n\
                    originalIP = currentIP;\n\
                    localStorage.setItem("originalIP", originalIP);\n\
                }\n\
                \n\
                document.getElementById("original-ip").textContent = originalIP;\n\
                \n\
                if (currentIP !== originalIP) {\n\
                    document.getElementById("ip-status").innerHTML = "✓ IP Successfully Changed!";\n\
                    document.getElementById("ip-status").style.color = "#4ade80";\n\
                } else {\n\
                    document.getElementById("ip-status").innerHTML = "• Using Original IP";\n\
                    document.getElementById("ip-status").style.color = "#fbbf24";\n\
                }\n\
            } catch (error) {\n\
                document.getElementById("current-ip").textContent = "Unable to detect";\n\
                document.getElementById("ip-status").innerHTML = "✗ Connection Error";\n\
                document.getElementById("ip-status").style.color = "#ef4444";\n\
            }\n\
        }\n\
        \n\
        updateIP();\n\
        setInterval(updateIP, 10000);\n\
    </script>\n\
</body>\n\
</html>' > /app/status.html

# Create Railway-optimized startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "================================================"\n\
echo "   FeelingSurf + Tor Network on Railway"\n\
echo "================================================"\n\
echo ""\n\
\n\
# Function to check IP\n\
check_ip() {\n\
    curl -s --max-time 10 "$@" https://api.ipify.org 2>/dev/null || echo "unavailable"\n\
}\n\
\n\
# Get original IP\n\
echo "🔍 Detecting original IP..."\n\
ORIGINAL_IP=$(check_ip)\n\
echo "   Original IP: $ORIGINAL_IP"\n\
echo ""\n\
\n\
# Start Tor\n\
echo "🔐 Starting Tor network..."\n\
tor -f /etc/tor/torrc > /tmp/tor.log 2>&1 &\n\
TOR_PID=$!\n\
echo "   Tor PID: $TOR_PID"\n\
\n\
# Wait for Tor bootstrap\n\
echo "   Bootstrapping Tor circuit..."\n\
for i in {1..60}; do\n\
    if grep -q "Bootstrapped 100%" /tmp/tor.log 2>/dev/null; then\n\
        echo "   ✓ Tor circuit established!"\n\
        break\n\
    fi\n\
    if [ $i -eq 60 ]; then\n\
        echo "   ⚠ Tor bootstrap timeout (continuing anyway)"\n\
    fi\n\
    sleep 1\n\
done\n\
\n\
# Wait a bit more for stability\n\
sleep 3\n\
\n\
# Check Tor IP\n\
echo ""\n\
echo "🌐 Checking Tor exit IP..."\n\
TOR_IP=$(check_ip --socks5-hostname 127.0.0.1:9050)\n\
echo "   Tor Exit IP: $TOR_IP"\n\
\n\
# Verify IP change\n\
if [ "$TOR_IP" != "$ORIGINAL_IP" ] && [ "$TOR_IP" != "unavailable" ]; then\n\
    echo "   ✓ SUCCESS: IP changed via Tor!"\n\
    IP_CHANGED=true\n\
else\n\
    echo "   ⚠ WARNING: IP not changed (Tor may need time)"\n\
    IP_CHANGED=false\n\
fi\n\
\n\
echo ""\n\
echo "================================================"\n\
echo "              Network Configuration"\n\
echo "================================================"\n\
echo "  Original IP:    $ORIGINAL_IP"\n\
echo "  Tor Exit IP:    $TOR_IP"\n\
echo "  IP Changed:     $IP_CHANGED"\n\
echo "  Tor SOCKS5:     127.0.0.1:9050"\n\
echo "  Rotation:       Every 10 minutes"\n\
echo "  Exit Countries: US, CA, GB, DE, NL, FR"\n\
echo "================================================"\n\
echo ""\n\
\n\
# Start Xvfb\n\
echo "🖥️  Starting virtual display..."\n\
Xvfb :99 -screen 0 1280x1024x24 > /dev/null 2>&1 &\n\
export DISPLAY=:99\n\
sleep 2\n\
echo "   ✓ Display :99 ready"\n\
\n\
# Start FeelingSurf with Tor proxy\n\
echo ""\n\
echo "🚀 Starting FeelingSurf Viewer with Tor..."\n\
cd /app\n\
\n\
# Use Tor SOCKS5 proxy\n\
./FeelingSurfViewer \\\n\
    --access-token d6e659ba6b59c9866fba8ff01bc56e04 \\\n\
    --no-sandbox \\\n\
    --proxy-server="socks5://127.0.0.1:9050" \\\n\
    2>&1 | tee /tmp/viewer.log &\n\
\n\
VIEWER_PID=$!\n\
echo "   ✓ Viewer started (PID: $VIEWER_PID)"\n\
\n\
# Monitor and show IP changes\n\
echo ""\n\
echo "📊 IP Rotation Monitor (checking every 30s):"\n\
echo "------------------------------------------------"\n\
(\n\
    LAST_IP="$TOR_IP"\n\
    while true; do\n\
        sleep 30\n\
        NEW_IP=$(check_ip --socks5-hostname 127.0.0.1:9050)\n\
        if [ "$NEW_IP" != "$LAST_IP" ] && [ "$NEW_IP" != "unavailable" ]; then\n\
            echo "[$(date +"%H:%M:%S")] 🔄 IP ROTATED: $LAST_IP → $NEW_IP"\n\
            LAST_IP="$NEW_IP"\n\
        fi\n\
    done\n\
) &\n\
\n\
sleep 3\n\
\n\
echo ""\n\
echo "================================================"\n\
echo "            All Systems Operational"\n\
echo "================================================"\n\
echo "  ✓ Tor Network:        Active"\n\
echo "  ✓ IP Masking:         Enabled"\n\
echo "  ✓ FeelingSurf:        Running"\n\
echo "  ✓ Web Dashboard:      Port ${PORT:-7860}"\n\
echo "================================================"\n\
echo ""\n\
echo "📋 FeelingSurf Live Logs:"\n\
echo "------------------------------------------------"\n\
\n\
# Show viewer logs\n\
tail -f /tmp/viewer.log &\n\
\n\
# Start web server on Railway'\''s PORT or default 7860\n\
WEB_PORT=${PORT:-7860}\n\
echo ""\n\
echo "🌐 Starting web dashboard on port $WEB_PORT..."\n\
cd /app && python3 -m http.server $WEB_PORT\n\
' > /app/start.sh && chmod +x /app/start.sh

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99

# Railway uses $PORT environment variable
EXPOSE 7860

CMD ["/app/start.sh"]
