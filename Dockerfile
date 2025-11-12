FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install all required dependencies including GLib and graphics libraries
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
    libglib2.0-0 \
    libgtk-3-0 \
    libnotify4 \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libdrm2 \
    libatk-bridge2.0-0 \
    libatspi2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set working directory
WORKDIR /app

# Download and extract FeelingSurf
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Create status page
RUN echo '<!DOCTYPE html><html><head><title>FeelingSurf</title><meta http-equiv="refresh" content="30"><style>body{font-family:sans-serif;margin:40px;background:#f5f5f5}.container{background:white;padding:20px;border-radius:10px;max-width:500px;margin:0 auto}.status{color:green;font-weight:bold}.info{margin-top:15px;color:#666}</style></head><body><div class="container"><div class="status">🟢 FeelingSurf Running</div><div class="info"><p><strong>RAM:</strong> 512MB Optimized</p><p><strong>Port:</strong> 8000</p><p><strong>Status:</strong> All dependencies loaded</p></div></div></body></html>' > /app/status.html

# Create startup script
RUN echo '#!/bin/bash\n\
echo "Starting FeelingSurf Viewer (512MB Optimized)"\n\
\n\
# Get IP info\n\
CURRENT_IP=$(curl -s -H "Accept: application/json" https://api.ipify.org?format=json | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" 2>/dev/null || echo "Unknown")\n\
echo "IP: $CURRENT_IP | RAM: 512MB | Port: 8000"\n\
echo "========================================="\n\
\n\
# Start minimal Xvfb\n\
echo "Starting virtual display..."\n\
Xvfb :99 -screen 0 800x600x16 -ac -nolisten tcp > /dev/null 2>&1 &\n\
export DISPLAY=:99\n\
sleep 2\n\
\n\
# Start HTTP server in background\n\
cd /app && python3 -m http.server 8000 &\n\
\n\
echo "Web server started on port 8000"\n\
echo "Starting FeelingSurf with memory optimization..."\n\
\n\
# Try starting FeelingSurf with memory optimizations\n\
ATTEMPT=1\n\
while [ $ATTEMPT -le 2 ]; do\n\
    echo "Attempt $ATTEMPT: Starting viewer..."\n\
    \n\
    case $ATTEMPT in\n\
        1)\n\
            # Aggressive memory saving\n\
            ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage --disable-gpu --single-process --memory-pressure-off --max-old-space-size=128 2>&1\n\
            ;;\n\
        2)\n\
            # Minimal flags\n\
            ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage --disable-gpu 2>&1\n\
            ;;\n\
    esac\n\
    \n\
    EXIT_CODE=$?\n\
    if [ $EXIT_CODE -eq 127 ]; then\n\
        echo "ERROR: Missing libraries detected. Check dependencies."\n\
        break\n\
    elif [ $EXIT_CODE -eq 0 ]; then\n\
        echo "FeelingSurf started successfully!"\n\
        break\n\
    else\n\
        echo "Attempt $ATTEMPT failed with exit code $EXIT_CODE. Restarting in 10 seconds..."\n\
        sleep 10\n\
        ATTEMPT=$((ATTEMPT + 1))\n\
    fi\n\
done\n\
\n\
if [ $ATTEMPT -gt 2 ]; then\n\
    echo "All startup attempts failed, but web interface remains active."\n\
fi\n\
\n\
# Keep container alive\n\
while true; do\n\
    sleep 300\n\
done' > /app/start.sh && chmod +x /app/start.sh

# Set environment variables
ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99

EXPOSE 8000

CMD ["/app/start.sh"]
