#!/bin/sh
set -e

# SIGHUP-handler
sighup_handler() {
  echo "Reloading nginx configuration and certificates..."
  nginx -s reload
}

# SIGTERM-handler
sigterm_handler() {
  # kubernetes sends a sigterm, where nginx needs SIGQUIT for graceful shutdown
  echo "Gracefully shutting down nginx..."
  nginx -s quit
}

# setup handlers
echo "Setting up signal handlers..."
trap 'sighup_handler' 1
trap 'sigterm_handler' 15

# substitute envvars in nginx.conf
echo "Generating nginx.conf..."
cat /tmpl/nginx.conf.tmpl | envsubst \$OFFLOAD_TO_HOST,\$OFFLOAD_TO_PORT,\$HEALT_CHECK_PATH,\$ALLOW_CIDRS,\$SERVICE_NAME,\$NAMESPACE > /etc/nginx/nginx.conf

# substitute envvars in prometheus.lua
echo "Generating prometheus.lua..."
cat /tmpl/prometheus.lua.tmpl | envsubst \$DEFAULT_BUCKETS > /lua-modules/prometheus.lua

# run nginx
echo "Starting nginx..."
nginx &

# watch for ssl certificate updates
echo "Starting inotifywait..."
while inotifywait -e modify /etc/ssl/private; do
  echo "Files in /etc/ssl/private changed, reloading nginx..."
  nginx -s reload
done