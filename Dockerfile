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
            <p style="margin-top: 30px; color: #888; font-size: 14px;">This viewer runs in the background and automatically visits websites. Check the logs below for activity details.</p>\n\
        </div>\n\
    </div>\n\
</body>\n\
</html>' > /app/status.html

# Create startup script
RUN echo '#!/bin/bash\n\
echo "Starting FeelingSurf Viewer..."\n\
\n\
# Get current Hugging Face IP address\n\
echo "=== Current Hugging Face Space Information ==="\n\
CURRENT_IP=$(curl -s -H "Accept: application/json" https://api.ipify.org?format=json | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")\n\
if [ -n "$CURRENT_IP" ]; then\n\
    echo "🌐 Current Public IP: $CURRENT_IP"\n\
    echo "📍 Hugging Face Space IP: $CURRENT_IP"\n\
else\n\
    echo "⚠️  Could not determine current IP address"\n\
fi\n\
echo "============================================="\n\
echo ""\n\
\n\
# Start Xvfb (virtual display)\n\
Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &\n\
export DISPLAY=:99\n\
\n\
# Wait for Xvfb to start\n\
sleep 2\n\
\n\
# Start FeelingSurf in background\n\
cd /app\n\
./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox 2>&1 | tee /tmp/viewer.log &\n\
\n\
# Wait for viewer to initialize\n\
sleep 5\n\
\n\
# Start web server on port 7860\n\
echo "Web interface available on port 7860"\n\
echo ""\n\
echo "=== FeelingSurf Viewer Logs ==="\n\
tail -f /tmp/viewer.log &\n\
cd /app && python3 -m http.server 7860' > /app/start.sh && \
    chmod +x /app/start.sh

# Set environment
ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"
ENV DISPLAY=:99

EXPOSE 7860

CMD ["/app/start.sh"]
