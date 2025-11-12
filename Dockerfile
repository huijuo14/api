FROM feelingsurf/viewer:stable

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Install PM2 process manager
RUN npm install -g pm2

# Create PM2 configuration file
RUN echo 'module.exports = {\n\
  apps: [\n\
    { name: "viewer-1", script: "/app/node_modules/.bin/next", args: "start -p 3000", cwd: "/app" },\n\
    { name: "viewer-2", script: "/app/node_modules/.bin/next", args: "start -p 3001", cwd: "/app" },\n\
    { name: "viewer-3", script: "/app/node_modules/.bin/next", args: "start -p 3002", cwd: "/app" }\n\
  ]\n\
}' > ecosystem.config.js

CMD ["pm2-runtime", "ecosystem.config.js"]
