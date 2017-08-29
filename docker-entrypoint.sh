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

# enforce https
if [ "${ENFORCE_HTTPS}" != "true" ]
then
  proxy_pass_default_server='location / { \
      proxy_pass http://${OFFLOAD_TO_HOST}:${OFFLOAD_TO_PORT}; \
    }'
  sed -i "s#return 301 https://\$host\$request_uri;#${proxy_pass_default_server}#g" ${NGINX_CONF_TMPL_PATH}
fi

# Generate .htpasswd file via htpasswd if the ACL_USERS environment variable is defined
# File is stored under /etc/nginx/.htpasswd
#
# Example usage:
#   ACL_USERS="user1:pass1 user2:abc123" entrypoint.sh
#
# Usage in Nginx:
#   auth_basic "Restricted";
#   auth_basic_user_file /etc/nginx/.htpasswd;

if [ -n "$ACL_USERS" ]
then
  echo "Setting up ACL users..."

  touch /etc/nginx/.htpasswd

  echo $ACL_USERS | awk '{
    split($0,creds," ")
    for (i in creds) {
      split(creds[i],user,":")
      system("htpasswd -b /etc/nginx/.htpasswd " user[1] " " user[2])
    }
  }'
fi

# substitute envvars in nginx.conf
echo "Generating nginx.conf..."
cat ${NGINX_CONF_TMPL_PATH} | envsubst \$OFFLOAD_TO_HOST,\$OFFLOAD_TO_PORT,\$HEALT_CHECK_PATH,\$ALLOW_CIDRS,\$SERVICE_NAME,\$NAMESPACE,\$DNS_ZONE,\$CLIENT_BODY_TIMEOUT,\$CLIENT_HEADER_TIMEOUT,\$KEEPALIVE_TIMEOUT,\$KEEPALIVE_REQUESTS,\$SEND_TIMEOUT,\$PROXY_CONNECT_TIMEOUT,\$PROXY_SEND_TIMEOUT,\$PROXY_READ_TIMEOUT,\$PROMETHEUS_METRICS_PORT > /etc/nginx/nginx.conf

# substitute envvars in prometheus.lua
echo "Generating prometheus.lua..."
cat ${PROMETHEUS_LUA_TMPL_PATH} | envsubst \$DEFAULT_BUCKETS > /lua-modules/prometheus.lua

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
