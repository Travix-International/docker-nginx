FROM nginx:1.11.10-alpine

MAINTAINER Travix

COPY nginx.conf /etc/nginx/nginx.conf.tmpl

# runtime environment variables
ENV OFFLOAD_TO_HOST=localhost \
    OFFLOAD_TO_PORT=80

CMD cat /etc/nginx/nginx.conf.tmpl | envsubst \$OFFLOAD_TO_HOST,\$OFFLOAD_TO_PORT > /etc/nginx/nginx.conf && nginx