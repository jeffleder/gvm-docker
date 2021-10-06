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
#ADD LAUNCH SCRIPT
COPY launch.sh /
RUN chmod +x /launch.sh
CMD /launch.sh
