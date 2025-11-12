FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    xvfb \
    python3 \
    curl \
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
    dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Download and extract FeelingSurf (use x64 version for Hugging Face)
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Create status page
RUN echo '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>FeelingSurf Viewer</title>\n\
    <meta http-equiv="refresh" content="10">\n\
    <style>\n\
        body { font-family: system-ui; margin: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; }\n\
        .container { background: white; padding: 40px; border-radius: 20px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); max-width: 600px; }\n\
        .status { color: #28a745; font-size: 32px; font-weight: bold; margin-bottom: 20px; }\n\
        .pulse { animation: pulse 2s infinite; }\n\
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }\n\
        .info { margin-top: 20px; color: #555; line-height: 1.8; }\n\
        .info strong { color: #333; }\n\
        .badge { display: inline-block; background: #e7f3ff; color: #0066cc; padding: 4px 12px; border-radius: 12px; font-size: 14px; margin: 5px 5px 5px 0; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <div class="status pulse">✅ FeelingSurf Viewer Active</div>\n\
        <div class="info">\n\
            <p><strong>Status:</strong> <span class="badge">Running</span></p>\n\
            <p><strong>User:</strong> alllogin</p>\n\
            <p><strong>Mode:</strong> Headless Browser</p>\n\
            <p><strong>Version:</strong> 2.5.0</p>\n\
            <p><strong>Port:</strong> 8000</p>\n\
            <p style="margin-top: 30px; color: #888; font-size: 14px;">This viewer runs in the background and automatically visits websites. Check the logs below for activity details.</p>\n\
        </div>\n\
    </div>\n\
</body>\n\
</html>' > /app/status.html

# Create startup script with memory optimizations
RUN echo '#!/bin/bash\n\
echo "Starting FeelingSurf Viewer..."\n\
\n\
# Set virtual memory limits to prevent OOM\n\
echo "=== Setting up virtual memory and environment ==="\n\
sysctl -w vm.overcommit_memory=1 2>/dev/null || true\n\
sysctl -w vm.drop_caches=1 2>/dev/null || true\n\
\n\
# Get current IP address\n\
CURRENT_IP=$(curl -s -H "Accept: application/json" https://api.ipify.org?format=json | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")\n\
if [ -n "$CURRENT_IP" ]; then\n\
    echo "🌐 Current Public IP: $CURRENT_IP"\n\
    echo "📍 Space IP: $CURRENT_IP"\n\
else\n\
    echo "⚠️  Could not determine current IP address"\n\
fi\n\
\n\
# Start D-Bus for system services\n\
echo "Starting D-Bus..."\n\
mkdir -p /var/run/dbus\n\
dbus-uuidgen --ensure\n\
dbus-daemon --system --fork\n\
\n\
# Start Xvfb (virtual display) with larger memory allocation\n\
echo "Starting virtual display..."\n\
Xvfb :99 -screen 0 1024x768x16 -ac +extension GLX +render -noreset > /dev/null 2>&1 &\n\
export DISPLAY=:99\n\
\n\
# Wait for Xvfb to start\n\
sleep 3\n\
\n\
# Set Chrome/Chromium flags to reduce memory usage\n\
export FEELINGSURF_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-rasterizer --disable-extensions --disable-background-timer-throttling --disable-renderer-backgrounding --disable-backgrounding-occluded-windows --memory-pressure-off --max-old-space-size=512"\n\
\n\
# Start FeelingSurf with memory optimizations\n\
echo "Starting FeelingSurf Viewer..."\n\
cd /app\n\
\n\
# Run viewer with timeout and restart on failure\n\
while true; do\n\
    echo "$(date): Starting FeelingSurf session..." >> /tmp/viewer-sessions.log\n\
    timeout 3600 ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage --disable-gpu --memory-pressure-off 2>&1 | tee -a /tmp/viewer.log\n\
    EXIT_CODE=${PIPESTATUS[0]}\n\
    echo "$(date): FeelingSurf exited with code $EXIT_CODE. Restarting in 10 seconds..." >> /tmp/viewer-sessions.log\n\
    sleep 10\n\
    \n\
    # Clear memory caches before restart\n\
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true\n\
done &\n\
\n\
# Wait for viewer to initialize\n\
sleep 10\n\
\n\
# Start web server on port 8000\n\
echo "=== Service Status ===\n\
✅ Web interface: http://0.0.0.0:8000\n\
✅ FeelingSurf Viewer: Running with auto-restart\n\
✅ Virtual Display: Active (:99)\n\
========================================="\n\
\n\
# Start simple HTTP server for status page\n\
cd /app && python3 -m http.server 8000' > /app/start.sh && \
    chmod +x /app/start.sh

# Set environment variables for memory optimization
ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99
ENV FEELINGSURF_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --memory-pressure-off"

# Set memory limits at container level (informational)
ENV NODE_OPTIONS="--max-old-space-size=512"
ENV UV_THREADPOOL_SIZE=1

EXPOSE 8000

CMD ["/app/start.sh"]
