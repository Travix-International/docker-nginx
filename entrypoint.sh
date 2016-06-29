#!/bin/sh

set -e

nginx_config_file=/etc/nginx/nginx.conf

deluser $USER_NAME
addgroup -S -g $GROUP_ID $GROUP_NAME
adduser -S -G $GROUP_NAME -u $USER_ID $USER_NAME
chown $USER_NAME:$GROUP_NAME -R /tmp/nginx/client_body_temp /tmp/nginx/proxy_temp

WHITELIST_CIDRS=${WHITELIST_CIDRS:-""}

rules=""
if [ "${WHITELIST_CIDRS}" != "" ]
then
  rules="satisfy any;"

  for ip in $WHITELIST_CIDRS
  do
    rules=$(echo "${rules}\n        allow ${ip};")
  done

  rules=$(echo "${rules}\n        deny all;")
fi

sed -i -e "s_allow    all;_${rules}_g" $nginx_config_file
sed -i -e "s/localhost:80/${BACKEND_SERVER}:${BACKEND_SERVER_PORT}/" $nginx_config_file

exec "$@"
