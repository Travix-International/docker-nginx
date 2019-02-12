FROM debian:stretch-slim

WORKDIR /app

RUN apt-get update; \
    apt-get install -y curl gnupg2 ca-certificates dpkg-dev git libpcre3 libpcre3-dev zlib1g zlib1g-dev; \
    echo "deb http://nginx.org/packages/debian stretch nginx" | tee /etc/apt/sources.list.d/nginx.list; \
    echo "deb-src http://nginx.org/packages/debian stretch nginx" | tee /etc/apt/sources.list.d/nginx.list; \
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - ; \
    apt-get update; \
    apt-get autoclean && apt-get autoremove;

RUN cd /app && apt-get source nginx; \ 
    cd /app/ && git clone https://github.com/chobits/ngx_http_proxy_connect_module; \
    cd /app/nginx-* && patch -p1 < ../ngx_http_proxy_connect_module/patch/proxy_connect_1014.patch; \
    cd /app/nginx-* && ./configure --with-http_stub_status_module --add-module=/app/ngx_http_proxy_connect_module && make && make install;

EXPOSE 8888

CMD /usr/local/nginx/sbin/nginx
