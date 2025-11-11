FROM feelingsurf/viewer:stable

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Run in headless mode to save memory
CMD ./run.sh --headless --disable-gpu --no-sandbox --disable-dev-shm-usage
