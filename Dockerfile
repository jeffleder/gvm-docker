FROM ubuntu:20.04
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/gvm/bin:/opt/gvm/sbin:/opt/gvm/.local/bin" \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    NODE_OPTIONS=--max_old_space_size=8192 \
    PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH \
    PYTHONPATH=/opt/gvm/lib/python3.8/site-packages \
    gvm_libs_version='v11.0.1' \
    openvas_smb_version='v1.0.5' \
    gvmd_version='v9.0.1' \
    openvas_scanner_version='v7.0.1' \
    gsa_version='v9.0.1' \
    ospd_version='v2.0.1' \
    ospd_openvas_version='v1.0.1'
RUN echo 'Installing standard dependencies' && \
    apt-get -y -qq update >/dev/null && \
    apt-get -y -qq --no-install-recommends install \
    bison \
    clang-format \
    cmake \
    curl \
    doxygen \
    flex \
    g++ \
    gcc \
    gcc-mingw-w64 \
    gettext \
    git \
    gnutls-bin \
    heimdal-dev \
    libglib2.0-dev \
    libgnutls28-dev \
    libgpgme-dev \
    libhiredis-dev \
    libical-dev \
    libksba-dev \
    libldap2-dev \
    libldap2-dev \
    libmicrohttpd-dev \
    libpcap-dev \
    libpopt-dev \
    libradcli-dev \
    libsnmp-dev \
    libssh-gcrypt-dev \
    libxml2-dev \
    libxslt1.1 \
    libxslt1-dev \
    make \
    nano \
    nmap \
    perl-base \
    pkg-config \
    python3-defusedxml \
    python3-dev \
    python3-lxml \
    python3-paramiko \
    python3-pip \
    python3-polib \
    python3-setuptools \
    redis \
    rsync \
    texlive-fonts-recommended \
    texlive-latex-extra \
    uuid-dev \
    xml-twig-tools \
    xmltoman \
    xsltproc \
    zlib1g-dev \
    >/dev/null
RUN echo 'Installing yarn' && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg|apt-key add - >/dev/null && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main"|tee /etc/apt/sources.list.d/yarn.list >/dev/null && \
    apt-get -y -qq update >/dev/null && \
    apt-get -y -qq install yarn >/dev/null
RUN echo 'Installing and configuring postgresql' && \
    apt-get -y -qq --no-install-recommends install postgresql postgresql-contrib postgresql-server-dev-all >/dev/null && \
    /usr/bin/pg_ctlcluster --skip-systemctl-redirect 12 main start && \
    su -c 'createuser -DRS root' postgres >/dev/null && \
    su -c 'createdb -O root gvmd' postgres >/dev/null && \
    su -c 'psql --dbname=gvmd --command="create role dba with superuser noinherit;"' postgres >/dev/null && \
    su -c 'psql --dbname=gvmd --command="grant dba to root;"' postgres >/dev/null && \
    su -c 'psql --dbname=gvmd --command="create extension \"uuid-ossp\";"' postgres >/dev/null && \
    /usr/bin/pg_ctlcluster --skip-systemctl-redirect 12 main stop
RUN echo 'Updating system path and creating build/install directories' && \
    echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/gvm/bin:/opt/gvm/sbin:/opt/gvm/.local/bin"' > /etc/environment && \
    echo '/opt/gvm/lib' > /etc/ld.so.conf.d/gvm.conf && \
    mkdir /build && \
    mkdir -p /opt/gvm/lib/python3.8/site-packages/
RUN echo 'Installing gvm-libs' && \
    cd /build && \
    curl -L --silent https://github.com/greenbone/gvm-libs/archive/$gvm_libs_version.tar.gz --output $gvm_libs_version.tar.gz && \
    tar -zxf $gvm_libs_version.tar.gz --strip-components=1 && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/gvm . >/dev/null && \
    make >/dev/null && \
    make install >/dev/null && \
    rm -rf *
RUN echo 'Installing openvas-smb' && \
    cd /build && \
    curl -L --silent https://github.com/greenbone/openvas-smb/archive/$openvas_smb_version.tar.gz --output $openvas_smb_version.tar.gz && \
    tar -zxf $openvas_smb_version.tar.gz --strip-components=1 && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/gvm . >/dev/null && \
    make >/dev/null && \
    make install >/dev/null && \
    rm -rf *
RUN echo 'Installing gvmd' && \
    cd /build && \
    curl -L --silent https://github.com/greenbone/gvmd/archive/$gvmd_version.tar.gz --output $gvmd_version.tar.gz && \
    tar -zxf $gvmd_version.tar.gz --strip-components=1 && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/gvm . >/dev/null && \
    make >/dev/null && \
    make install >/dev/null && \
    rm -rf *
RUN echo 'Installing openvas-scanner' && \
    cd /build && \
    curl -L --silent https://github.com/greenbone/openvas-scanner/archive/$openvas_scanner_version.tar.gz --output $openvas_scanner_version.tar.gz && \
    tar -zxf $openvas_scanner_version.tar.gz --strip-components=1 && \
    cp ./config/redis-openvas.conf /etc/redis/ && \
    sed -i 's/set (CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${COVERAGE_FLAGS}")/set (CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Werror -Wno-error=deprecated-declarations")/' CMakeLists.txt && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/gvm . >/dev/null && \
    make >/dev/null && \
    make install >/dev/null && \
    rm -rf *
RUN echo 'Installing gsa' && \
    cd /build && \
    curl -L --silent https://github.com/greenbone/gsa/archive/$gsa_version.tar.gz --output $gsa_version.tar.gz && \
    tar -zxf $gsa_version.tar.gz --strip-components=1 && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/gvm . >/dev/null && \
    make >/dev/null && \
    make install >/dev/null && \
    rm -rf *
RUN echo 'Installing ospd' && \
    cd /build && \
    curl -L --silent https://github.com/greenbone/ospd/archive/$ospd_version.tar.gz --output $ospd_version.tar.gz && \
    tar -zxf $ospd_version.tar.gz --strip-components=1 && \
    python3 setup.py install --prefix=/opt/gvm && \
    rm -rf *
RUN echo 'Installing ospd-openvas' && \
    cd /build && \
    curl -L --silent https://github.com/greenbone/ospd-openvas/archive/$ospd_openvas_version.tar.gz --output $ospd_openvas_version.tar.gz && \
    tar -zxf $ospd_openvas_version.tar.gz --strip-components=1 && \
    python3 setup.py install --prefix=/opt/gvm && \
    rm -rf *
#RUN echo 'Installing python-gvm' && \
#    pip3 -qq install python-gvm
#RUN echo 'Installing gvm-tools' && \
#    pip3 -qq install gvm-tools
RUN echo 'Reconfiguring redis' && \
    ldconfig && \
    mkdir /run/redis-openvas/ && \
    chown redis:redis /etc/redis/redis-openvas.conf && \
    echo 'db_address = /run/redis-openvas/redis.sock' > /opt/gvm/etc/openvas/openvas.conf
RUN echo 'Syncing and importing feeds' && \
    echo '--> Starting Redis' && \
    redis-server /etc/redis/redis-openvas.conf && \
    echo '--> Starting PostgreSQL' && \
    /usr/bin/pg_ctlcluster --skip-systemctl-redirect 12 main start && \
    echo '--> Starting OSPd' && \
    ospd-openvas --pid-file /opt/gvm/var/run/ospd-openvas.pid --log-file /opt/gvm/var/log/gvm/ospd-openvas.log --lock-file-dir /opt/gvm/var/run -u /opt/gvm/var/run/ospd.sock && \
    echo '--> Starting GVMd' && \
    gvmd --osp-vt-update=/opt/gvm/var/run/ospd.sock && \
    echo '--> Syncing NVTs' && \
    sed -i 's/if \[ \"`id -u`\" -eq \"0\" \]/if [ 1 -eq 2 ]/' /opt/gvm/bin/greenbone-nvt-sync && \
    greenbone-nvt-sync --curl >/dev/null || true && \
    sleep 300 && \
    greenbone-nvt-sync >/dev/null || true && \
    sleep 300 && \
    greenbone-nvt-sync >/dev/null || true && \
    sleep 300 && \
    echo '--> Syncing SCAP Data' && \
    greenbone-scapdata-sync --curl >/dev/null || true && \
    sleep 300 && \
    greenbone-scapdata-sync >/dev/null || true && \
    sleep 300 && \
    greenbone-scapdata-sync >/dev/null || true && \
    sleep 300 && \
    echo '--> Syncing CERT Data' && \
    greenbone-certdata-sync --curl >/dev/null || true && \
    sleep 300 && \
    greenbone-certdata-sync >/dev/null || true && \
    sleep 300 && \
    greenbone-certdata-sync >/dev/null || true && \
    sleep 300 && \
    echo '--> Loading NVTs into redis' && \
    openvas --update-vt-info || true && \
    echo '--> Modifying "OpenVAS Default" scanner-host' && \
    gvmd --modify-scanner=08b69003-5fc2-4037-a479-93b440211c73 --scanner-host=/opt/gvm/var/run/ospd.sock && \
    echo '--> Stopping Redis' && \
    redis-cli -s /run/redis-openvas/redis.sock shutdown && \
    echo '--> Stopping PostgreSQL' && \
    /usr/bin/pg_ctlcluster --skip-systemctl-redirect 12 main stop
COPY start.sh /
RUN chmod +x /start.sh
RUN echo 'Setup complete!!!'
CMD '/start.sh'
