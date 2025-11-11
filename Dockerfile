FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget unzip curl \
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxrandr2 libgbm1 libxss1 libgtk-3-0

# Download FeelingSurf
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip
RUN unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip
RUN chmod +x FeelingSurfViewer

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

CMD ./FeelingSurfViewer --headless --disable-gpu --no-sandbox --max-old-space-size=256
