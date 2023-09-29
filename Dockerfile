FROM nginx:mainline-alpine@sha256:34b58b4f5c6d133d97298cbaae140283dc325ff1aeffb28176f63078baeffd14

RUN apk add --no-cache rsync

### rsyncd.conf
RUN <<__DOCKER_EOF__
cat <<__EOF__ > /etc/rsyncd.conf
# /etc/rsyncd.conf
# Minimal configuration file for rsync daemon.
# See rsync(1) and rsyncd.conf(5) man pages for help.
# Do not set "pid file" here.

use chroot = no
read only = no

[data]
path = /usr/share/nginx/html
read only = no
timeout = 30
uid = root
gid = root
__EOF__
__DOCKER_EOF__

### nginx healthcheck
RUN <<__DOCKER_EOF__
cat <<__EOF__ > /etc/nginx/conf.d/healthcheck.conf
server {
    listen       81;
    server_name  localhost;

    location /health {
        return 200;
    }
}
__EOF__
__DOCKER_EOF__

### start script
RUN <<__DOCKER_EOF__
cat <<__EOF__ > /start
#!/bin/sh
mkdir -p /usr/share/nginx/html
chmod a+x /usr/share/nginx
chmod a+x /usr/share/nginx/html
chmod a+r /usr/share/nginx
chmod a+r /usr/share/nginx/html
chmod g+r /usr/share/nginx/html

rsync --daemon --config /etc/rsyncd.conf --log-file=/var/log/rsyncd.log
nginx

exec tail -f /var/log/rsyncd.log /var/log/nginx/access.log /var/log/nginx/error.log
__EOF__
__DOCKER_EOF__

RUN chmod +x /start

EXPOSE 873
EXPOSE 80

CMD ["/start"]
