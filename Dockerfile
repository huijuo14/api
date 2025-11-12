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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Download and extract FeelingSurf
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Create ultra-light status page
RUN echo '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>FeelingSurf</title>\n\
    <meta http-equiv="refresh" content="15">\n\
    <style>\n\
        body { font-family: sans-serif; margin: 20px; background: #f5f5f5; }\n\
        .container { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }\n\
        .status { color: #28a745; font-size: 18px; font-weight: bold; }\n\
        .info { margin-top: 15px; color: #666; font-size: 14px; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <div class="status">🟢 FeelingSurf Viewer (512MB Mode)</div>\n\
        <div class="info">\n\
            <p><strong>RAM:</strong> 512MB Optimized</p>\n\
            <p><strong>Status:</strong> Low-memory mode active</p>\n\
            <p><strong>Port:</strong> 8000</p>\n\
        </div>\n\
    </div>\n\
</body>\n\
</html>' > /app/status.html

# Create ultra-optimized startup script for 512MB
RUN echo '#!/bin/bash\n\
echo "Starting FeelingSurf Viewer (512MB Optimized)..."\n\
\n\
# Extreme memory optimization\n\necho "=== 512MB RAM Optimization ==="\n\
\n\
# Get IP info quickly\n\
IP=$(curl -s -m 5 https://api.ipify.org 2>/dev/null || echo "Unknown")\n\
echo "IP: $IP"\n\
\n\
# Start minimal Xvfb with tiny resolution\n\
echo "Starting minimal virtual display..."\n\
Xvfb :99 -screen 0 800x600x8 -ac -noreset > /dev/null 2>&1 &\n\
export DISPLAY=:99\n\
sleep 2\n\
\n\
# Set extreme memory limits\n\nexport FEELINGSURF_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-rasterizer --disable-extensions --disable-background-timer-throttling --disable-renderer-backgrounding --disable-backgrounding-occluded-windows --memory-pressure-off --max-old-space-size=256 --single-process --in-process-gpu --no-zygote --no-first-run --disable-features=VizDisplayCompositor --disable-threaded-animation --disable-threaded-scrolling --disable-checker-imaging --disable-image-animation-resync --disable-background-timer-throttling --disable-ipc-flooding-protection --disable-hang-monitor"\n\
\n\
# Start web server first (lightweight)\n\
cd /app && python3 -m http.server 8000 &\n\
\n\necho "Web interface: http://0.0.0.0:8000"\necho "Starting viewer in ultra-low-memory mode..."\n\
\n\
# Run viewer with very short sessions and frequent restarts\n\
while true; do\n\
    echo "$(date): Starting 5-minute session..." >> /tmp/sessions.log\n\
    \n\
    # Run with 5-minute timeout and minimal memory\n\
    timeout 300 ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 \\\n\
        --no-sandbox \\\n\
        --disable-dev-shm-usage \\\n\
        --disable-gpu \\\n\
        --disable-software-rasterizer \\\n\
        --disable-extensions \\\n\
        --single-process \\\n\
        --no-first-run \\\n\
        --memory-pressure-off \\\n\
        --max-old-space-size=128 \\\n\
        --disable-background-timer-throttling \\\n\
        --disable-renderer-backgrounding 2>&1 | tee -a /tmp/viewer.log\n\
    \n\
    EXIT_CODE=${PIPESTATUS[0]}\n\
    echo "$(date): Session ended (Code: $EXIT_CODE). Cooling down..." >> /tmp/sessions.log\n\
    \n\
    # Force memory cleanup\n\necho "Forcing memory cleanup..."\nsync\n\necho 1 > /proc/sys/vm/drop_caches 2>/dev/null || true\nsleep 30  # Longer cooldown for memory recovery\n    \ndone' > /app/start.sh && chmod +x /app/start.sh

# Set environment
ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99

EXPOSE 8000

CMD ["/app/start.sh"]
