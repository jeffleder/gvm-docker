#!/usr/bin/env bash
set -Eeuo pipefail
USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}
echo 'Starting Redis'
redis-server /etc/redis/redis-openvas.conf
while [ ! -S /run/redis-openvas/redis.sock ];do echo '--> Waiting for redis socket';sleep 1;done;
while [ "$(redis-cli -s /run/redis-openvas/redis.sock ping)" != 'PONG' ];do echo '--> Waiting for redis to respond';sleep 1;done;
echo 'Starting PostgreSQL'
/usr/bin/pg_ctlcluster --skip-systemctl-redirect 12 main start
echo 'Starting OSPd'
if [ -f /opt/gvm/var/run/feed-update.lock ];then echo '--> Removing stale feed-update.lock file';rm /opt/gvm/var/run/feed-update.lock;fi;
if [ -f /opt/gvm/var/run/ospd-openvas.pid ];then echo '--> Removing stale ospd-openvas.pid file';rm /opt/gvm/var/run/ospd-openvas.pid;fi;
if [ -S /opt/gvm/var/run/ospd.sock ];then echo '--> Removing stale ospd.sock file';rm /opt/gvm/var/run/ospd.sock;fi;
ospd-openvas --pid-file /opt/gvm/var/run/ospd-openvas.pid --log-file /opt/gvm/var/log/gvm/ospd-openvas.log --lock-file-dir /opt/gvm/var/run -u /opt/gvm/var/run/ospd.sock
while [ ! -S /opt/gvm/var/run/ospd.sock ];do echo '--> Waiting for OSPd socket';sleep 10;done;
echo 'Starting GVMd'
gvmd --osp-vt-update=/opt/gvm/var/run/ospd.sock
until gvmd --get-users;do echo '--> Waiting for GVMd socket';sleep 10;done;
if [ ! -f '/data/created_gvm_user' ];then echo 'Creating admin user';gvmd --create-user=${USERNAME} --password=${PASSWORD};touch /data/created_gvm_user;fi;
echo 'Starting GSA'
gsad --verbose --http-only --no-redirect --port=9392
echo '++++++++++++++++++++++++++++++++++++++++++++++'
echo '+ Your GVM 11 container is now ready to use! +'
echo '++++++++++++++++++++++++++++++++++++++++++++++'
echo ''
echo '++++++++++++++++'
echo '+ Tailing logs +'
echo '++++++++++++++++'
tail -F /opt/gvm/var/log/gvm/*
