FROM alpine:latest

# Install minimal dependencies
RUN apk add --no-cache \
    nodejs \
    npm \
    curl

# Download FeelingSurf directly (lighter than the full image)
RUN wget -q https://github.com/feelingsurf/viewer/releases/download/2.5.0/FeelingSurfViewer-linux-x64-2.5.0.zip
RUN unzip -q FeelingSurfViewer-linux-x64-2.5.0.zip
RUN chmod +x FeelingSurfViewer

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Run with memory limits
CMD ./FeelingSurfViewer --headless --disable-gpu --no-sandbox --max-old-space-size=256
