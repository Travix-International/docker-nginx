#!/bin/bash
set -e

# SIGHUP-handler
sighup_handler() {
  nginx_pid=$(cat /var/run/nginx.pid)
  echo "Forwarding SIGHUP to pid $nginx_pid..."
  kill -SIGUSR1 "$nginx_pid"
}

# SIGUSR1-handler
sigusr1_handler() {
  nginx_pid=$(cat /var/run/nginx.pid)
  echo "Forwarding SIGUSR1 to pid $nginx_pid..."
  kill -SIGUSR1 "$nginx_pid"
}

# SIGTERM-handler
sigterm_handler() {
  nginx_pid=$(cat /var/run/nginx.pid)
  echo "Forwarding SIGTERM to pid $nginx_pid..."
  kill -SIGTERM "$nginx_pid"
}

# setup handlers
echo "Setting up signal handlers..."
trap 'kill ${!}; sighup_handler' SIGHUP
trap 'kill ${!}; sigusr1_handler' SIGUSR1
trap 'kill ${!}; sigterm_handler' SIGTERM

# substitute envvars in nginx.conf
echo "Generating nginx.conf..."
cat /tmpl/nginx.conf.tmpl | envsubst \$OFFLOAD_TO_HOST,\$OFFLOAD_TO_PORT,\$HEALT_CHECK_PATH,\$ALLOW_CIDRS,\$SERVICE_NAME,\$NAMESPACE > /etc/nginx/nginx.conf

# substitute envvars in prometheus.lua
echo "Generating prometheus.lua..."
cat /tmpl/prometheus.lua.tmpl | envsubst \$DEFAULT_BUCKETS > /lua-modules/prometheus.lua

# run nginx
echo "Starting nginx..."
nginx