FROM travix/base-alpine:latest

MAINTAINER Travix

# build time environment variables
ENV NGINX_VERSION=1.8.1-r0 \
    USER_NAME=nginx \
    USER_ID=999 \
    GROUP_NAME=nginx \
    GROUP_ID=999

# install nginx
RUN addgroup -S -g $GROUP_ID $GROUP_NAME \
    && adduser -S -G $GROUP_NAME -u $USER_ID $USER_NAME \
    && apk --update add \
      nginx=${NGINX_VERSION} \
    && rm /var/cache/apk/* \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && mkdir -p /tmp/nginx/client_body_temp \
    && mkdir -p /tmp/nginx/proxy_temp

COPY nginx.conf /etc/nginx/nginx.conf

# expose ports
EXPOSE 80 443

# define default command
CMD deluser $USER_NAME; \
    addgroup -S -g $GROUP_ID $GROUP_NAME; \
    adduser -S -G $GROUP_NAME -u $USER_ID $USER_NAME; \
    chown $USER_NAME:$GROUP_NAME -R /tmp/nginx/client_body_temp /tmp/nginx/proxy_temp; \
    exec /usr/sbin/nginx;