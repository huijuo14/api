FROM feelingsurf/viewer:stable

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Set memory limits
ENV NODE_OPTIONS="--max-old-space-size=256"

# Run with optimized flags
CMD ./run.sh --headless --disable-gpu --no-sandbox --max-old-space-size=256
