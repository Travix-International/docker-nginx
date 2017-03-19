#!/bin/sh
set -e

# inspired by https://medium.com/@gchudnov/trapping-signals-in-docker-containers-7a57fdda7d86#.k9cjxrx6o

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
  echo "Finished shutting down nginx!"
}

# setup handlers
echo "Setting up signal handlers..."
trap 'kill ${!}; sighup_handler' 1 # SIGHUP
trap 'kill ${!}; sigterm_handler' 15 # SIGTERM

# substitute envvars in nginx.conf
echo "Generating nginx.conf..."
cat /tmpl/nginx.conf.tmpl | envsubst \$OFFLOAD_TO_HOST,\$OFFLOAD_TO_PORT,\$HEALT_CHECK_PATH,\$ALLOW_CIDRS,\$SERVICE_NAME,\$NAMESPACE > /etc/nginx/nginx.conf

# substitute envvars in prometheus.lua
echo "Generating prometheus.lua..."
cat /tmpl/prometheus.lua.tmpl | envsubst \$DEFAULT_BUCKETS > /lua-modules/prometheus.lua

# watch for ssl certificate changes
init_inotifywait() {
  echo "Starting inotifywait to detect changes in certificates..."
  while inotifywait -e modify,move,create,delete /etc/ssl/private/; do
    echo "Files in /etc/ssl/private changed, reloading nginx..."
    nginx -s reload
  done
}
init_inotifywait &

# run nginx
echo "Starting nginx..."
nginx &

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
