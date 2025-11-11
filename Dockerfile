FROM feelingsurf/viewer:stable

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Set memory limits for the app
ENV NODE_OPTIONS="--max-old-space-size=512"
ENV ELECTRON_DISABLE_GPU_SANDBOX=1
ENV ELECTRON_DISABLE_GPU=1

# Run with memory limits
CMD ./run.sh --disable-gpu --disable-software-rasterizer --no-sandbox --max-old-space-size=512
