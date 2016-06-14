# Usage

To run this docker container use the following command

```sh
docker run -d travix/nginx:latest
```

# Environment variables

In order to configure the nginx load balancer for providing ssl on port 443 for your gocd server you can use the following environment variables

| Name                 | Description                                               | Default value               |
| -------------------- | ----------------------------------------------------------| --------------------------- |
| BACKEND_SERVER       | The ip address of the gocd server                         | localhost                   |
| BACKEND_SERVER_PORT  | The http port the gocd server listens to                  | 80                          |

To run nginx to redirect to ssl and provide access through normal https port (443) to gocd server run the following command

```sh
docker run -d \
    -e "BACKEND_SERVER=origin.yourdomain.com" \
    -e "BACKEND_SERVER_PORT=8153" \
    travix/nginx:latest
```

# Mounting volumes

In order to keep your ssl certificate outside of the container on the host machine you can mount the following directories

| Directory         | Description               | Importance                                                           |
| ----------------- | ------------------------- | -------------------------------------------------------------------- |
| /etc/nginx        | Configuration for nginx   | If configuration needs to be different from the one in the container |
| /etc/ssl/certs    | CA certificates           | Keep these files safe                                                |
| /etc/ssl/private/ | SSL certificates          | Keep these files safe                                                |

Start the container like this to mount the directories

```sh
docker run -d \
    -e "BACKEND_SERVER=origin.yourdomain.com" \
    -e "BACKEND_SERVER_PORT=8153" \
    -v /mnt/persistent-disk/nginx/config:/etc/nginx
    -v /mnt/persistent-disk/nginx/ssl:/etc/ssl/private
    travix/nginx:latest
```

To make sure the process in the container can read and write to those directories create a user and group with same gid and uid on the host machine

```sh
groupadd -r -g 999 nginx
useradd -r -g nginx -u 999 nginx
```

And then change the owner of the host directories

```sh
chown -R nginx:nginx /mnt/persistent-disk/nginx/config
chown -R nginx:nginx /mnt/persistent-disk/nginx/ssl
```