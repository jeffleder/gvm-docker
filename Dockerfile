FROM debian:sid
RUN sed -i.bak 's/ main/ main contrib non-free/g' /etc/apt/sources.list
RUN echo 'debconf debconf/frontend select Noninteractive'|debconf-set-selections
RUN apt-get -y -qq update >/dev/null
RUN apt-get -y -qq install apt-utils >/dev/null
RUN apt-get -y -qq install net-tools >/dev/null
RUN apt-get -y -qq install procps >/dev/null
RUN apt-get -y -qq install nano >/dev/null
RUN apt-get -y -qq install gvm >/dev/null
RUN apt-get -y -qq install greenbone-security-assistant >/dev/null

RUN apt-get -y -qq install wget >/dev/null
RUN apt-get -y -qq install python >/dev/null
RUN wget -q https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py
RUN chmod 755 systemctl.py && cp systemctl.py /bin/systemctl

RUN sed -i.bak 's/systemctl start postgresql/service postgresql start/g' /usr/bin/gvm-setup
RUN sed -i.bak 's/systemctl start redis-server@openvas.service/#systemctl start redis-server@openvas.service/g' /usr/bin/gvm-feed-update
RUN install --directory --owner=redis --group=redis --mode=777 /run/redis-openvas/
RUN touch /var/log/redis/redis-server-openvas.log && chmod 777 /var/log/redis/redis-server-openvas.log
RUN runuser -u redis -- redis-server /etc/redis/redis-openvas.conf && gvm-setup
COPY launch.sh /
RUN chmod +x /launch.sh
CMD /launch.sh
