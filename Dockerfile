FROM feelingsurf/viewer:stable

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Install curl
RUN apt-get update && apt-get install -y curl

# Start FeelingSurf with continuous health checks
CMD ./run.sh & while true; do curl -f http://localhost:8000 || echo "Health check failed but continuing..."; sleep 30; done
