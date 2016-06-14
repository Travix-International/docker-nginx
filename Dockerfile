FROM travix/base-alpine:latest

MAINTAINER Travix

# build time environment variables
ENV USER_NAME=nginx \
    USER_ID=999 \
    GROUP_NAME=nginx \
    GROUP_ID=999

# install nginx
RUN addgroup -S -g $GROUP_ID $GROUP_NAME \
    && adduser -S -G $GROUP_NAME -u $USER_ID $USER_NAME \
    && apk --update add \
    nginx \
    && rm /var/cache/apk/* \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && mkdir -p /tmp/nginx/client_body_temp \
    && mkdir -p /tmp/nginx/proxy_temp

ADD nginx.conf /etc/nginx/nginx.conf
ADD ssl/ssl.pem /etc/ssl/private/ssl.pem
ADD ssl/ssl.key /etc/ssl/private/ssl.key

# expose ports
EXPOSE 80 443

# runtime environment variables
ENV BACKEND_SERVER=localhost \
    BACKEND_SERVER_PORT=80

# define default command
CMD deluser $USER_NAME; \
    addgroup -S -g $GROUP_ID $GROUP_NAME; \
    adduser -S -G $GROUP_NAME -u $USER_ID $USER_NAME; \
    chown $USER_NAME:$GROUP_NAME -R /tmp/nginx/client_body_temp /tmp/nginx/proxy_temp; \
    sed -i -e "s/localhost:80/${BACKEND_SERVER}:${BACKEND_SERVER_PORT}/" /etc/nginx/nginx.conf; \
    exec /usr/sbin/nginx;