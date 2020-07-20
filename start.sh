#!/usr/bin/env bash
set -Eeuo pipefail
USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}
echo 'Starting Redis'
if [ -S /run/redis/redis.sock ];then echo '--> Removing stale redis socket'; rm /run/redis/redis.sock;fi;
redis-server --unixsocket /run/redis/redis.sock --unixsocketperm 700 --timeout 0 --databases 128 --maxclients 512 --daemonize yes --port 6379 --bind 0.0.0.0
while [ ! -S /run/redis/redis.sock ];do echo '--> Waiting for redis socket';sleep 1;done;
while [ "$(redis-cli -s /run/redis/redis.sock ping)" != 'PONG' ];do echo '--> Waiting for redis to respond';sleep 1;done;
echo 'Starting PostgreSQL'
/usr/bin/pg_ctlcluster --skip-systemctl-redirect 10 main start
echo 'Starting OSPd'
if [ -f /var/run/ospd.pid ];then echo '--> Removing stale /var/run/OSPd pid file';rm /var/run/ospd.pid;fi;
if [ -f /run/ospd.pid ];then echo '--> Removing stale /run/OSPd pid file';rm /run/ospd.pid;fi;
if [ -S /tmp/ospd.sock ];then echo '--> Removing stale /tmp/ospd.sock file';rm /tmp/ospd.sock;fi;
if [ -L /run/openvassd.sock ];then echo '--> Removing stale /run/openvassd.sock file';rm /run/openvassd.sock;fi;
ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log --unix-socket /tmp/ospd.sock --log-level INFO
while [ ! -S /tmp/ospd.sock ];do echo '--> Waiting for OSPd socket';sleep 1;done;
if [ ! -L /var/run/openvassd.sock ];then echo '--> Fixing OSPd socket link';rm -f /var/run/openvassd.sock;ln -s /tmp/ospd.sock /var/run/openvassd.sock;fi;
chmod 666 /tmp/ospd.sock
echo 'Starting GVMd'
su -c 'gvmd --osp-vt-update=/tmp/ospd.sock' gvm
if [ ! -L /var/run/gvmd.sock ];then echo '--> Fixing GVMd socket link';rm -f /var/run/gvmd.sock;ln -s /usr/local/var/run/gvmd.sock /var/run/gvmd.sock;fi;
until su -c 'gvmd --get-users' gvm;do sleep 1;done;
if [ ! -f '/data/created_gvm_user' ];then echo 'Creating admin user';su -c 'gvmd --create-user=${USERNAME} --password=${PASSWORD}' gvm;touch /data/created_gvm_user;fi;
echo 'Starting GSA'
su -c "gsad --verbose --http-only --no-redirect --port=9392" gvm
echo '++++++++++++++++++++++++++++++++++++++++++++++'
echo '+ Your GVM 11 container is now ready to use! +'
echo '++++++++++++++++++++++++++++++++++++++++++++++'
echo ''
echo '++++++++++++++++'
echo '+ Tailing logs +'
echo '++++++++++++++++'
tail -F /usr/local/var/log/gvm/*
