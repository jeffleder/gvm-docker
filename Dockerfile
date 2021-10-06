FROM debian:sid
#INSTALL PACKAGES
RUN sed -i.bak 's/ main/ main contrib non-free/g' /etc/apt/sources.list
RUN echo 'debconf debconf/frontend select Noninteractive'|debconf-set-selections
RUN apt-get -y -qq update >/dev/null
RUN apt-get -y -qq install apt-utils >/dev/null
RUN apt-get -y -qq install net-tools >/dev/null
RUN apt-get -y -qq install procps >/dev/null
RUN apt-get -y -qq install nano >/dev/null
RUN apt-get -y -qq install gvm >/dev/null
RUN apt-get -y -qq install greenbone-security-assistant >/dev/null
#CONFIGURE REDIS
RUN cp /etc/redis/redis.conf /etc/redis/redis.conf.bak && cp /etc/redis/redis-openvas.conf /etc/redis/redis.conf
RUN mkdir --mode=777 /var/run/redis-openvas/
RUN touch /var/log/redis/redis-server-openvas.log && chmod 777 /var/log/redis/redis-server-openvas.log
#PREP AND RUN GVM-SETUP
#RUN sed -i.bak 's/gvm-feed-update/#gvm-feed-update/' /usr/bin/gvm-setup
RUN sed -i.bak 's/systemctl start postgresql/#systemctl start postgresql/' /usr/bin/gvm-setup
RUN sed -i.bak 's/if ! systemctl is-active --quiet postgresql; then/if false; then/' /usr/bin/gvm-setup
RUN sed -i.bak 's/systemctl start redis-server@openvas.service/#systemctl start redis-server@openvas.service/' /usr/bin/gvm-feed-update
RUN service postgresql start && service redis-server start \
  && gvm-setup \
  && service redis-server stop && service postgresql stop
/*
#PREP AND RUN GVM-FEED-UPDATE
RUN service postgresql start && service redis-server start \
  #START OSPD-OPENVAS
  && if [ -f /var/lib/openvas/feed-update.lock ];then echo 'Removing stale feed-update.lock file';rm /var/lib/openvas/feed-update.lock;fi \
  && if [ -f /run/ospd/ospd-openvas.pid ];then echo 'Removing stale ospd-openvas.pid file';rm /run/ospd/ospd-openvas.pid;fi \
  && if [ -S /run/ospd/ospd.sock ];then echo 'Removing stale ospd.sock file';rm /run/ospd/ospd.sock;fi \
  && install --directory --owner=_gvm --group=_gvm --mode=777 /run/ospd/ \
  && runuser -u _gvm -- ospd-openvas --unix-socket /run/ospd/ospd.sock --pid-file /run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-openvas.log --lock-file-dir /var/lib/openvas \
  && while [ ! -S /run/ospd/ospd.sock ];do echo 'Waiting for OSPd socket';sleep 10;done \
  #START GVMD
  && install --directory --owner=_gvm --group=_gvm --mode=777 /run/gvm/ \
  && runuser -u _gvm -- gvmd --osp-vt-update=/run/ospd/ospd.sock \
  #RUN GVM-FEED-UPDATE
  && gvm-feed-update \
  && while [ "$(cat /var/log/gvm/gvmd.log|grep -c 'update_scap_end: Updating SCAP info succeeded')" != 1 ];do sleep 1;done \
  && service redis-server stop && service postgresql stop
*/
#ADD LAUNCH SCRIPT
COPY launch.sh /
RUN chmod +x /launch.sh
CMD /launch.sh
