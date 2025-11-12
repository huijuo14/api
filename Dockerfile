FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install minimal dependencies only
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    xvfb \
    python3 \
    curl \
    libnss3 \
    libxss1 \
    libxtst6 \
    libasound2 \
    libgbm1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set working directory
WORKDIR /app

# Download and extract FeelingSurf
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Create ultra-lightweight status page
RUN echo '<!DOCTYPE html><html><head><title>FeelingSurf</title><meta http-equiv="refresh" content="30"><style>body{font-family:sans-serif;margin:40px;background:#f5f5f5}.container{background:white;padding:20px;border-radius:10px;max-width:500px;margin:0 auto}.status{color:green;font-weight:bold}.info{margin-top:15px;color:#666}</style></head><body><div class="container"><div class="status">🟢 FeelingSurf Running</div><div class="info"><p><strong>RAM:</strong> 512MB Optimized</p><p><strong>Port:</strong> 8000</p><p><strong>Mode:</strong> Minimal Memory</p></div></div></body></html>' > /app/status.html

# Create startup script for low-memory environment
RUN echo '#!/bin/bash\n\
echo "Starting FeelingSurf Viewer (512MB Optimized)"\n\
\n\
# Get IP info\n\
CURRENT_IP=$(curl -s -H "Accept: application/json" https://api.ipify.org?format=json | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" 2>/dev/null || echo "Unknown")\n\
echo "IP: $CURRENT_IP | RAM: 512MB | Port: 8000"\n\
echo "========================================="\n\
\n\
# Start minimal Xvfb with smallest possible configuration\n\
echo "Starting minimal virtual display..."\n\
Xvfb :99 -screen 0 800x600x8 -ac -nolisten tcp > /dev/null 2>&1 &\n\
export DISPLAY=:99\n\
sleep 2\n\
\n\
# Set environment for low memory\n\
export FEELINGSURF_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-rasterizer --disable-extensions --disable-background-timer-throttling --disable-renderer-backgrounding --disable-backgrounding-occluded-windows --memory-pressure-off --max-old-space-size=256 --single-process --in-process-gpu"\n\
\n\
# Start HTTP server in background\n\
cd /app && python3 -m http.server 8000 &\n\
\n\
echo "Web server started on port 8000"\n\
echo "Starting FeelingSurf with aggressive memory limits..."\n\
\n\
# Try to start FeelingSurf with multiple fallback strategies\n\
ATTEMPT=1\n\
while [ $ATTEMPT -le 3 ]; do\n\
    echo "Attempt $ATTEMPT: Starting viewer..."\n\
    \n\
    case $ATTEMPT in\n\
        1)\n\
            # Most aggressive memory saving\n\
            ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage --disable-gpu --single-process --memory-pressure-off --max-old-space-size=128 2>&1\n\
            ;;\n\
        2)\n\
            # Even more minimal\n\
            ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage --disable-gpu --single-process --no-startup-window 2>&1\n\
            ;;\n\
        3)\n\
            # Absolute minimum\n\
            ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage --single-process 2>&1\n\
            ;;\n\
    esac\n\
    \n\
    EXIT_CODE=$?\n\
    echo "Attempt $ATTEMPT failed with exit code $EXIT_CODE. Waiting 15 seconds..."\n\
    sleep 15\n\
    ATTEMPT=$((ATTEMPT + 1))\n\
done\n\
\n\
echo "All startup attempts failed. Container will remain running for web interface."\n\
\n\
# Keep container alive\n\
while true; do\n\
    sleep 300\n\
done' > /app/start.sh && chmod +x /app/start.sh

# Set environment variables
ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99
ENV FEELINGSURF_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --single-process --memory-pressure-off"

EXPOSE 8000

CMD ["/app/start.sh"]
