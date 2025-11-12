FROM feelingsurf/viewer:stable

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Create a simple script to run multiple instances
RUN echo '#!/bin/sh\n\
echo "Starting 3 FeelingSurf sessions..."\n\
\n\
# Start first instance (will use default port)\n\
/app/run.sh &\n\
\n\
# Start second instance\n\
/app/run.sh &\n\
\n\
# Start third instance\n\
/app/run.sh &\n\
\n\
# Keep container running\n\
wait' > /start-multiple.sh && chmod +x /start-multiple.sh

CMD ["/start-multiple.sh"]
