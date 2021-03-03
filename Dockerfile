#REF:https://www.agix.com.au/installing-openvas-on-kali-in-2020/
FROM debian:bullseye
#update sources.list (for greenbone-security-assistant)
RUN sed -i.bak 's/ main/ main contrib non-free/g' /etc/apt/sources.list
RUN apt-get -y -qq update >/dev/null
RUN apt-get -y -qq install gvm >/dev/null
RUN apt-get -y -qq install greenbone-security-assistant >/dev/null
#switch postgresql service start syntax in /usr/bin/gvm-setup
RUN sed -i.bak 's/systemctl start postgresql/service postgresql start/g' /usr/bin/gvm-setup
#disable redis service start in /usr/bin/gvm-feed-update (launched at beginning of next step instead)
RUN sed -i.bak 's/systemctl start redis-server@openvas.service/#systemctl start redis-server@openvas.service/g' /usr/bin/gvm-feed-update
RUN echo 'Starting Redis and running setup' && \
    mkdir -p /run/redis-openvas/ && chown redis:redis /run/redis-openvas/ && chmod 755 /run/redis-openvas/ && \
    touch /var/log/redis/redis-server-openvas.log && chmod 777 /var/log/redis/redis-server-openvas.log && \
    runuser -u redis -- redis-server /etc/redis/redis-openvas.conf && \
	gvm-setup >/dev/null
COPY start.sh /
RUN chmod +x /start.sh
CMD '/start.sh'