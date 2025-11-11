FROM feelingsurf/viewer:stable

# Set your access token
ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Install curl for health checks
RUN apt-get update && apt-get install -y curl

# Create health check script
RUN echo '#!/bin/bash\n\necho "Starting FeelingSurf with health checks..."\n\n# Start FeelingSurf in background\n./run.sh &\n\n# Health check loop - keeps container alive\nwhile true; do\n    # Check if FeelingSurf is responding\n    if curl -f http://localhost:3000 >/dev/null 2>&1; then\n        echo "✅ FeelingSurf is healthy"\n    else\n        echo "❌ FeelingSurf health check failed, but keeping container alive"\n    fi\n    \n    # Also prevent sleep by writing to stdout\n    echo "🕒 Heartbeat: $(date)"\n    \n    # Wait before next check\n    sleep 30\ndone' > /start.sh

RUN chmod +x /start.sh

# Use the health check script
CMD ["/start.sh"]
