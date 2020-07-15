#!/usr/bin/env bash
set -Eeuo pipefail
USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}
echo 'Setting up redis'
if [ ! -d '/run/redis' ];then mkdir /run/redis;fi;
rm /run/redis/redis.sock &>/dev/null
if [ -S /run/redis/redis.sock ];then rm /run/redis/redis.sock;fi;
redis-server --unixsocket /run/redis/redis.sock --unixsocketperm 700 --timeout 0 --databases 128 --maxclients 512 --daemonize yes --port 6379 --bind 127.0.0.1
echo 'Waiting for redis socket'
while [ ! -S /run/redis/redis.sock ];do sleep 1;done;
echo 'Waiting for redis to respond'
REDIS_PING="$(redis-cli -s /run/redis/redis.sock ping)"
while [ "${REDIS_PING}" != 'PONG' ];do sleep 1;REDIS_PING="$(redis-cli -s /run/redis/redis.sock ping)";done;
if [ ! -d /data ];then echo 'Creating data folder';mkdir /data;fi;
if [ ! -d /data/database ];then
	echo 'Creating database folder'
	mv /var/lib/postgresql/10/main /data/database
	ln -s /data/database /var/lib/postgresql/10/main
	chown postgres:postgres -R /var/lib/postgresql/10/main
	chown postgres:postgres -R /data/database
fi
if [ ! -L /var/lib/postgresql/10/main ];then
	echo 'Fixing database folder'
	rm -rf /var/lib/postgresql/10/main
	ln -s /data/database /var/lib/postgresql/10/main
	chown postgres:postgres -R /var/lib/postgresql/10/main
	chown postgres:postgres -R /data/database
fi
if [ ! -L /usr/local/var/lib ];then
	echo 'Fixing local/var/lib'
	if [ ! -d /data/var-lib ];then mkdir /data/var-lib;fi
	cp -rf /usr/local/var/lib/* /data/var-lib
	rm -rf /usr/local/var/lib
	ln -s /data/var-lib /usr/local/var/lib
fi
if [ ! -L /usr/local/share ];then
	echo 'Fixing local/share'
	if [ ! -d /data/local-share ];then mkdir /data/local-share;fi
	cp -rf /usr/local/share/* /data/local-share/
	rm -rf /usr/local/share
	ln -s /data/local-share /usr/local/share
fi
echo 'Starting PostgreSQL'
/usr/bin/pg_ctlcluster --skip-systemctl-redirect 10 main start
if [ ! -f '/firstrun' ];then
	echo 'Performing firstrun tasks'
	echo '--> Creating nvt sync user'
	useradd --home-dir /usr/local/share/openvas openvas-sync
	chown openvas-sync:openvas-sync -R /usr/local/share/openvas
	chown openvas-sync:openvas-sync -R /usr/local/var/lib/openvas
	echo '--> Creating gvm user'
	useradd --home-dir /usr/local/share/gvm gvm
	chown gvm:gvm -R /usr/local/share/gvm
	if [ ! -d /usr/local/var/lib/gvm/cert-data ];then mkdir -p /usr/local/var/lib/gvm/cert-data;fi
	chown gvm:gvm -R /usr/local/var/lib/gvm
	chmod 770 -R /usr/local/var/lib/gvm
	chown gvm:gvm -R /usr/local/var/log/gvm
	chown gvm:gvm -R /usr/local/var/run
	adduser openvas-sync gvm
	adduser gvm openvas-sync
	touch /firstrun
fi
if [ ! -f '/data/firstrun' ];then
	echo 'Creating GVM database'
	su -c 'createuser -DRS gvm' postgres
	su -c 'createdb -O gvm gvmd' postgres
	su -c 'psql --dbname=gvmd --command="create role dba with superuser noinherit;"' postgres
	su -c 'psql --dbname=gvmd --command="grant dba to gvm;"' postgres
	su -c 'psql --dbname=gvmd --command="create extension \"uuid-ossp\";"' postgres
	touch /data/firstrun
fi
if [ -f /var/run/ospd.pid ];then rm /var/run/ospd.pid;fi;
if [ -S /tmp/ospd.sock ];then rm /tmp/ospd.sock;fi;
echo 'Starting OSPd'
ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log --unix-socket /tmp/ospd.sock --log-level INFO
while [ ! -S /tmp/ospd.sock ];do sleep 1;done;
if [ ! -L /var/run/openvassd.sock ];then echo 'Fixing OSPd socket';rm -f /var/run/openvassd.sock;ln -s /tmp/ospd.sock /var/run/openvassd.sock;fi;
chmod 666 /tmp/ospd.sock
# echo 'Migrating database if needed'
# su -c "gvmd -m" gvm
echo 'Starting GVMd'
su -c 'gvmd --osp-vt-update=/tmp/ospd.sock' gvm
if [ ! -L /var/run/gvmd.sock ];then echo 'fixing GVMd socket';rm -f /var/run/gvmd.sock;ln -s /usr/local/var/run/gvmd.sock /var/run/gvmd.sock;fi;
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