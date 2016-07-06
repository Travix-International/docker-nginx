FROM travix/base-alpine:latest

MAINTAINER Travix

# build time environment variables
ENV USER_NAME=nginx \
    USER_ID=999 \
    GROUP_NAME=nginx \
    GROUP_ID=999 \
    NGINX_VERSION=1.10.1

RUN addgroup -S -g $GROUP_ID $GROUP_NAME \
    && adduser -S -G $GROUP_NAME -u $USER_ID $USER_NAME

# Install nginx
RUN apk --update add build-base pcre-dev openssl-dev \
    && mkdir -p /tmp/src \
    && cd /tmp/src \
    && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -zxvf nginx-${NGINX_VERSION}.tar.gz \
    && cd /tmp/src/nginx-${NGINX_VERSION} \
    && ./configure \
        --prefix=/usr/share/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=stderr \
        --http-log-path=/dev/stdout \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security' \
        --with-http_realip_module \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-ipv6 \
        --with-ld-opt='-Wl,-z,relro -Wl,--as-needed' \
        --with-pcre-jit \
        --with-stream \
        --with-stream_ssl_module \
        --with-threads \
        --without-http_memcached_module \
        --without-mail_imap_module \
        --without-mail_pop3_module \
        --without-mail_smtp_module \
    && make install \
    && cd ../../ && rm -rf src \
    && mkdir /var/cache/nginx \
    && rm /etc/nginx/*.default \
    && apk del build-base && rm /var/cache/apk/* \
    && mkdir -p \
        /tmp/nginx/client_body_temp \
        /tmp/nginx/proxy_temp

ADD entrypoint.sh /entrypoint.sh
ADD nginx.conf /etc/nginx/nginx.conf
ADD ssl/ssl.pem /etc/ssl/private/ssl.pem
ADD ssl/ssl.key /etc/ssl/private/ssl.key

# expose ports
EXPOSE 80 81 443

# runtime environment variables
ENV BACKEND_SERVER=localhost \
    BACKEND_SERVER_PORT=80 \
    WHITELIST_CIDRS=""

# entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# start nginx
CMD ["nginx"]
