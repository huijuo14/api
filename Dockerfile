FROM feelingsurf/viewer:stable

# Install proxy tools and dependencies
USER root
RUN apt-get update && apt-get install -y \
    curl \
    python3 \
    python3-pip \
    wget \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Python proxy library
RUN pip3 install requests

# Create proxy fetcher and rotator
RUN echo '#!/usr/bin/env python3\n\
import requests\n\
import json\n\
import sys\n\
import time\n\
import random\n\
\n\
def fetch_working_proxies():\n\
    """Fetch working proxies from multiple free sources"""\n\
    proxies = []\n\
    \n\
    # Source 1: ProxyScrape (most reliable)\n\
    try:\n\
        print("Fetching proxies from ProxyScrape...")\n\
        r = requests.get(\n\
            "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all&ssl=yes&anonymity=elite",\n\
            timeout=15\n\
        )\n\
        if r.status_code == 200:\n\
            for proxy in r.text.strip().split("\\n")[:30]:\n\
                if proxy:\n\
                    proxies.append(f"http://{proxy.strip()}")\n\
    except Exception as e:\n\
        print(f"ProxyScrape error: {e}")\n\
    \n\
    # Source 2: Free Proxy List\n\
    try:\n\
        print("Fetching proxies from FreeProxyList...")\n\
        r = requests.get(\n\
            "https://www.proxy-list.download/api/v1/get?type=http&anon=elite",\n\
            timeout=15\n\
        )\n\
        if r.status_code == 200:\n\
            for proxy in r.text.strip().split("\\n")[:30]:\n\
                if proxy:\n\
                    proxies.append(f"http://{proxy.strip()}")\n\
    except Exception as e:\n\
        print(f"FreeProxyList error: {e}")\n\
    \n\
    # Test proxies quickly\n\
    print(f"Testing {len(proxies)} proxies...")\n\
    working = []\n\
    \n\
    for proxy in proxies[:50]:  # Test first 50\n\
        try:\n\
            r = requests.get(\n\
                "https://api.ipify.org",\n\
                proxies={"http": proxy, "https": proxy},\n\
                timeout=5\n\
            )\n\
            if r.status_code == 200:\n\
                working.append(proxy)\n\
                print(f"✓ Working: {proxy}")\n\
                if len(working) >= 10:  # Keep 10 working proxies\n\
                    break\n\
        except:\n\
            pass\n\
    \n\
    return working\n\
\n\
def get_best_proxy():\n\
    """Get a single best working proxy"""\n\
    proxies = fetch_working_proxies()\n\
    if proxies:\n\
        best = random.choice(proxies)\n\
        print(f"Selected proxy: {best}")\n\
        return best\n\
    return None\n\
\n\
if __name__ == "__main__":\n\
    proxy = get_best_proxy()\n\
    if proxy:\n\
        # Extract host:port\n\
        proxy_addr = proxy.replace("http://", "")\n\
        print(proxy_addr)\n\
        sys.exit(0)\n\
    else:\n\
        print("No working proxies found")\n\
        sys.exit(1)\n\
' > /app/get_proxy.py && chmod +x /app/get_proxy.py

# Create enhanced status page
RUN echo '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>FeelingSurf with Proxy Rotation</title>\n\
    <meta http-equiv="refresh" content="15">\n\
    <style>\n\
        * { margin: 0; padding: 0; box-sizing: border-box; }\n\
        body { font-family: -apple-system, system-ui, sans-serif; background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }\n\
        .container { background: rgba(255,255,255,0.05); backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,0.1); padding: 50px; border-radius: 30px; box-shadow: 0 30px 90px rgba(0,0,0,0.6); max-width: 850px; width: 100%; }\n\
        .header { text-align: center; margin-bottom: 40px; }\n\
        .icon { font-size: 80px; margin-bottom: 20px; animation: bounce 2s infinite; }\n\
        @keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-20px); } }\n\
        h1 { font-size: 36px; color: white; margin-bottom: 10px; background: linear-gradient(135deg, #667eea, #764ba2); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }\n\
        .subtitle { color: rgba(255,255,255,0.6); font-size: 15px; }\n\
        .status { display: inline-flex; align-items: center; gap: 10px; background: rgba(40,167,69,0.2); border: 2px solid #28a745; padding: 10px 25px; border-radius: 30px; color: #4ade80; font-weight: 600; margin-top: 15px; }\n\
        .pulse { width: 10px; height: 10px; background: #4ade80; border-radius: 50%; animation: pulse 2s infinite; box-shadow: 0 0 15px #4ade80; }\n\
        @keyframes pulse { 0%, 100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.5; transform: scale(1.3); } }\n\
        .ip-display { background: linear-gradient(135deg, rgba(102,126,234,0.3), rgba(118,75,162,0.3)); border: 1px solid rgba(102,126,234,0.5); padding: 40px; border-radius: 20px; margin: 30px 0; position: relative; overflow: hidden; }\n\
        .ip-display::before { content: ""; position: absolute; width: 200%; height: 200%; background: radial-gradient(circle, rgba(255,255,255,0.1), transparent 60%); animation: rotate 4s linear infinite; }\n\
        @keyframes rotate { 0% { transform: translate(-50%, -50%) rotate(0deg); } 100% { transform: translate(-50%, -50%) rotate(360deg); } }\n\
        .ip-row { display: flex; justify-content: space-between; margin: 20px 0; position: relative; z-index: 1; }\n\
        .ip-label { color: rgba(255,255,255,0.7); font-size: 13px; text-transform: uppercase; letter-spacing: 2px; }\n\
        .ip-value { color: white; font-size: 28px; font-weight: bold; font-family: "Monaco", monospace; text-shadow: 0 2px 15px rgba(102,126,234,0.6); }\n\
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 20px; margin: 30px 0; }\n\
        .stat { background: rgba(255,255,255,0.05); padding: 25px; border-radius: 15px; text-align: center; border: 1px solid rgba(255,255,255,0.1); transition: all 0.3s; }\n\
        .stat:hover { background: rgba(255,255,255,0.1); transform: translateY(-5px); }\n\
        .stat-icon { font-size: 32px; margin-bottom: 12px; }\n\
        .stat-label { color: rgba(255,255,255,0.5); font-size: 11px; text-transform: uppercase; margin-bottom: 10px; }\n\
        .stat-value { color: white; font-size: 22px; font-weight: bold; }\n\
        .footer { margin-top: 35px; padding-top: 25px; border-top: 1px solid rgba(255,255,255,0.1); text-align: center; color: rgba(255,255,255,0.4); font-size: 13px; }\n\
        .badge { display: inline-block; background: linear-gradient(135deg, #8b5cf6, #6366f1); padding: 6px 15px; border-radius: 20px; font-size: 11px; font-weight: 600; color: white; margin-top: 10px; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <div class="header">\n\
            <div class="icon">🌍</div>\n\
            <h1>FeelingSurf + Proxy Network</h1>\n\
            <div class="subtitle">Smart Proxy Rotation • Railway Deployment</div>\n\
            <div class="status">\n\
                <span class="pulse"></span>\n\
                System Active\n\
            </div>\n\
        </div>\n\
        \n\
        <div class="ip-display">\n\
            <div class="ip-row">\n\
                <span class="ip-label">Current External IP</span>\n\
                <span class="ip-value" id="current-ip">Loading...</span>\n\
            </div>\n\
            <div class="ip-row">\n\
                <span class="ip-label">Original Server IP</span>\n\
                <span class="ip-value" id="original-ip">---</span>\n\
            </div>\n\
        </div>\n\
        \n\
        <div class="stats">\n\
            <div class="stat">\n\
                <div class="stat-icon">👤</div>\n\
                <div class="stat-label">User</div>\n\
                <div class="stat-value">alllogin</div>\n\
            </div>\n\
            <div class="stat">\n\
                <div class="stat-icon">🔄</div>\n\
                <div class="stat-label">Proxy Type</div>\n\
                <div class="stat-value">HTTP/S</div>\n\
            </div>\n\
            <div class="stat">\n\
                <div class="stat-icon">🚀</div>\n\
                <div class="stat-label">Status</div>\n\
                <div class="stat-value" style="color: #4ade80;">Running</div>\n\
            </div>\n\
            <div class="stat">\n\
                <div class="stat-icon">📦</div>\n\
                <div class="stat-label">Version</div>\n\
                <div class="stat-value">2.5.0</div>\n\
            </div>\n\
        </div>\n\
        \n\
        <div class="footer">\n\
            Auto-refreshing every 15 seconds • Proxy rotation active<br>\n\
            <span class="badge">Powered by Railway</span>\n\
        </div>\n\
    </div>\n\
    <script>\n\
        let originalIP = localStorage.getItem("original-ip");\n\
        \n\
        async function updateIP() {\n\
            try {\n\
                const res = await fetch("https://api.ipify.org?format=json");\n\
                const data = await res.json();\n\
                document.getElementById("current-ip").textContent = data.ip;\n\
                \n\
                if (!originalIP) {\n\
                    originalIP = data.ip;\n\
                    localStorage.setItem("original-ip", originalIP);\n\
                }\n\
                document.getElementById("original-ip").textContent = originalIP;\n\
            } catch (e) {\n\
                document.getElementById("current-ip").textContent = "Unable to detect";\n\
            }\n\
        }\n\
        updateIP();\n\
    </script>\n\
</body>\n\
</html>' > /app/status.html

# Create startup script with proxy rotation
RUN echo '#!/bin/bash\n\
\n\
echo "================================================"\n\
echo "  FeelingSurf + Proxy Rotation on Railway"\n\
echo "================================================"\n\
echo ""\n\
\n\
# Check original IP\n\
echo "🔍 Checking original IP..."\n\
ORIGINAL_IP=$(curl -s --max-time 10 https://api.ipify.org || echo "unavailable")\n\
echo "   Original IP: $ORIGINAL_IP"\n\
echo ""\n\
\n\
# Try to get working proxy (skip if fails)\n\
echo "🌐 Fetching working proxies..."\n\
PROXY=$(python3 /app/get_proxy.py 2>&1 | tail -n1)\n\
\n\
if [ ! -z "$PROXY" ] && [ "$PROXY" != "No working proxies found" ]; then\n\
    echo "   ✓ Found proxy: $PROXY"\n\
    \n\
    # Test the proxy\n\
    PROXY_IP=$(curl -s --max-time 10 --proxy "$PROXY" https://api.ipify.org 2>/dev/null || echo "unavailable")\n\
    \n\
    if [ "$PROXY_IP" != "unavailable" ] && [ "$PROXY_IP" != "$ORIGINAL_IP" ]; then\n\
        echo "   ✓ Proxy working! New IP: $PROXY_IP"\n\
        USE_PROXY=true\n\
        PROXY_ARG="--proxy-server=http://$PROXY"\n\
    else\n\
        echo "   ✗ Proxy not working, using direct connection"\n\
        USE_PROXY=false\n\
        PROXY_ARG=""\n\
    fi\n\
else\n\
    echo "   ⚠ No proxies available, using direct connection"\n\
    USE_PROXY=false\n\
    PROXY_ARG=""\n\
fi\n\
\n\
echo ""\n\
echo "================================================"\n\
echo "  Configuration Summary"\n\
echo "================================================"\n\
echo "  Original IP:  $ORIGINAL_IP"\n\
if [ "$USE_PROXY" = true ]; then\n\
    echo "  Proxy IP:     $PROXY_IP"\n\
    echo "  Proxy Server: $PROXY"\n\
    echo "  Mode:         Proxied"\n\
else\n\
    echo "  Mode:         Direct Connection"\n\
fi\n\
echo "================================================"\n\
echo ""\n\
\n\
# Start FeelingSurf with or without proxy\n\
echo "🚀 Starting FeelingSurf Viewer..."\n\
cd /app\n\
\n\
if [ "$USE_PROXY" = true ]; then\n\
    ./FeelingSurfViewer \\\n\
        --access-token d6e659ba6b59c9866fba8ff01bc56e04 \\\n\
        --no-sandbox \\\n\
        $PROXY_ARG \\\n\
        2>&1 | tee /tmp/viewer.log &\n\
else\n\
    ./FeelingSurfViewer \\\n\
        --access-token d6e659ba6b59c9866fba8ff01bc56e04 \\\n\
        --no-sandbox \\\n\
        2>&1 | tee /tmp/viewer.log &\n\
fi\n\
\n\
VIEWER_PID=$!\n\
echo "   ✓ Viewer started (PID: $VIEWER_PID)"\n\
sleep 5\n\
\n\
echo ""\n\
echo "================================================"\n\
echo "  System Status"\n\
echo "================================================"\n\
if [ "$USE_PROXY" = true ]; then\n\
    echo "  ✓ Proxy:           Active"\n\
else\n\
    echo "  ✓ Proxy:           Bypassed (direct)"\n\
fi\n\
echo "  ✓ FeelingSurf:     Running"\n\
echo "  ✓ Web Dashboard:   Port ${PORT:-8080}"\n\
echo "================================================"\n\
echo ""\n\
echo "📋 FeelingSurf Live Logs:"\n\
echo "------------------------------------------------"\n\
\n\
tail -f /tmp/viewer.log &\n\
\n\
# Start web server\n\
WEB_PORT=${PORT:-8080}\n\
cd /app && python3 -m http.server $WEB_PORT\n\
' > /app/start_with_proxy.sh && chmod +x /app/start_with_proxy.sh

# Switch back to non-root user
USER 1000

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

EXPOSE 8080

CMD ["/app/start_with_proxy.sh"]
