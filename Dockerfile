FROM feelingsurf/viewer:stable

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Install Node.js and PM2 (since npm isn't available in the base image)
RUN apt-get update && apt-get install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g pm2

# Create PM2 configuration file
RUN echo 'module.exports = {\n\
  apps: [\n\
    { name: "viewer-1", script: "/usr/local/bin/node", args: "/app/server.js", cwd: "/app", env: { PORT: 3000 } },\n\
    { name: "viewer-2", script: "/usr/local/bin/node", args: "/app/server.js", cwd: "/app", env: { PORT: 3001 } },\n\
    { name: "viewer-3", script: "/usr/local/bin/node", args: "/app/server.js", cwd: "/app", env: { PORT: 3002 } }\n\
  ]\n\
}' > ecosystem.config.js

CMD ["pm2-runtime", "ecosystem.config.js"]
