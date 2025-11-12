FROM alpine:3.18

# Use Alpine Linux for extreme minimalism
RUN apk add --no-cache \
    wget \
    unzip \
    xvfb \
    python3 \
    curl \
    libc6-compat \
    gcompat \
    nss \
    libxscrnsaver \
    libxrandr \
    libxdamage \
    mesa-gbm

# Set working directory
WORKDIR /app

# Download FeelingSurf
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip && \
    unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip && \
    rm FeelingSurfViewer-linux-x64-2.5.0.zip && \
    chmod +x FeelingSurfViewer

# Create minimal status page
RUN echo '<html><body><h3>FeelingSurf (512MB)</h3><p>Ultra-low-memory mode</p></body></html>' > /app/status.html

# Create micro startup script
RUN echo '#!/bin/sh\n\
echo "512MB RAM Mode - Starting..."\n\
\n\
# Start tiny Xvfb\n\
Xvfb :99 -screen 0 640x480x8 -ac > /dev/null 2>&1 &\nexport DISPLAY=:99\nsleep 2\n\n\
# Start web server\n\
python3 -m http.server 8000 &\n\n\
# Run viewer with extreme limits\n\
while true; do\n    timeout 180 ./FeelingSurfViewer --access-token d6e659ba6b59c9866fba8ff01bc56e04 --no-sandbox --disable-dev-shm-usage --disable-gpu --single-process --no-first-run 2>&1 | tail -5\n    echo "Restarting..."\n    sleep 20\ndone' > /app/start.sh && chmod +x /app/start.sh

ENV DISPLAY=:99
EXPOSE 8000
CMD ["/app/start.sh"]
