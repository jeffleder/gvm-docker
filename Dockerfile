FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    gvm_libs_version='v11.0.1' \
    openvas_scanner_version='v7.0.1' \
    gvmd_version='v9.0.1' \
    gsa_version='v9.0.1' \
    gvm_tools_version='v2.1.0' \
    openvas_smb_version='v1.0.5' \
    open_scanner_protocol_daemon_version='v2.0.1' \
    ospd_openvas_version='v1.0.1' \
    python_gvm_version='v1.5.0' \
    NODE_OPTIONS=--max_old_space_size=8192
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing standard dependencies' && \
    apt-get -y -qq update >/dev/null && \
    apt-get install -y -qq --no-install-recommends \
    bison \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    gcc \
    gcc-mingw-w64 \
    geoip-database \
    gnutls-bin \
    graphviz \
    heimdal-dev \
    ike-scan \
    libgcrypt20-dev \
    libglib2.0-dev \
    libgnutls28-dev \
    libgpgme11-dev \
    libgpgme-dev \
    libhiredis-dev \
    libical2-dev \
    libksba-dev \
    libmicrohttpd-dev \
    libnet-snmp-perl \
    libpcap-dev \
    libpopt-dev \
    libsnmp-dev \
    libssh-gcrypt-dev \
    libxml2-dev \
    locales-all \
    mailutils \
    net-tools \
    nmap \
    nsis \
    openssh-client \
    perl-base \
    pkg-config \
    postgresql \
    postgresql-contrib \
    postgresql-server-dev-all \
    python3-defusedxml \
    python3-dialog \
    python3-lxml \
    python3-paramiko \
    python3-pip \
    python3-polib \
    python3-psutil \
    python3-setuptools \
    redis-server \
    redis-tools \
    rsync \
    smbclient \
    texlive-fonts-recommended \
    texlive-latex-extra \
    uuid-dev \
    wapiti \
    wget \
    whiptail \
    xml-twig-tools \
    xsltproc \
    >/dev/null
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing node.js' && \
    curl -sL https://deb.nodesource.com/setup_12.x|bash - >/dev/null && \
    apt-get -y -qq install nodejs >/dev/null
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing yarn' && \
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg|apt-key add - >/dev/null && \
    echo 'deb https://dl.yarnpkg.com/debian/ stable main'|tee /etc/apt/sources.list.d/yarn.list >/dev/null && \
    apt-get -y -qq update >/dev/null && \
    apt-get -y -qq install yarn >/dev/null
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Creating build directory' && \
    mkdir /build
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing Greenbone Vulnerability Management libraries module' && \
    cd /build && \
    wget -q https://github.com/greenbone/gvm-libs/archive/$gvm_libs_version.tar.gz && \
    tar -zxf $gvm_libs_version.tar.gz --strip-components=1 && \
    cmake -DCMAKE_BUILD_TYPE=Release . >/dev/null && \
    make >/dev/null && \
    make install >/dev/null && \
    rm -rf *
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing OpenVAS Scanner smb module' && \
    cd /build && \
    wget -q https://github.com/greenbone/openvas-smb/archive/$openvas_smb_version.tar.gz && \
    tar -zxf $openvas_smb_version.tar.gz --strip-components=1 && \
    cmake -DCMAKE_BUILD_TYPE=Release . >/dev/null && \
    make >/dev/null && \
    make install >/dev/null && \
    rm -rf *
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing Greenbone Vulnerability Manager (GVMD)' && \
    cd /build && \
    wget -q https://github.com/greenbone/gvmd/archive/$gvmd_version.tar.gz && \
    tar -zxf $gvmd_version.tar.gz --strip-components=1 && \
    cmake -DCMAKE_BUILD_TYPE=Release . >/dev/null && \
    make >/dev/null && \
    make install >/dev/null && \
    rm -rf *
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing Open Vulnerability Assessment System (OpenVAS) Scanner' && \
    cd /build && \
    wget -q https://github.com/greenbone/openvas-scanner/archive/$openvas_scanner_version.tar.gz && \
    tar -zxf $openvas_scanner_version.tar.gz --strip-components=1 && \
    cmake -DCMAKE_BUILD_TYPE=Release . >/dev/null && \
    make >/dev/null && \
    make install >/dev/null && \
    rm -rf *
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing Greenbone Security Assistant (GSA)' && \
    cd /build && \
    wget -q https://github.com/greenbone/gsa/archive/$gsa_version.tar.gz && \
    tar -zxf $gsa_version.tar.gz --strip-components=1 && \
    cmake -DCMAKE_BUILD_TYPE=Release . >/dev/null && \
    make >/dev/null && \
    make install >/dev/null && \
    rm -rf *
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing Greenbone Vulnerability Management Python Library' && \
    pip3 -qq install python-gvm
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing Open Scanner Protocol daemon (OSPd)' && \
    cd /build && \
    wget -q https://github.com/greenbone/ospd/archive/$open_scanner_protocol_daemon_version.tar.gz && \
    tar -zxf $open_scanner_protocol_daemon_version.tar.gz --strip-components=1 && \
    python3 setup.py install && \
    rm -rf *
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing Open Scanner Protocol for OpenVAS' && \
    cd /build && \
    wget -q https://github.com/greenbone/ospd-openvas/archive/$ospd_openvas_version.tar.gz && \
    tar -zxf $ospd_openvas_version.tar.gz --strip-components=1 && \
    python3 setup.py install && \
    rm -rf *
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Installing GVM-Tools' && \
    pip3 install gvm-tools
RUN echo '---------------------------------------------------------------------------------------------' && \    
    echo 'Creating database and dba' && \
    su -c 'createuser -DRS gvm' postgres >/dev/null && \
    su -c 'createdb -O gvm gvmd' postgres >/dev/null && \
    su -c 'psql --dbname=gvmd --command="create role dba with superuser noinherit;"' postgres >/dev/null && \
    su -c 'psql --dbname=gvmd --command="grant dba to gvm;"' postgres >/dev/null && \
    su -c 'psql --dbname=gvmd --command="create extension \"uuid-ossp\";"' postgres >/dev/null

RUN echo '---------------------------------------------------------------------------------------------' && \   
    echo 'Creating gvm user'
    useradd --home-dir /usr/local/share/gvm gvm
    if [ ! -d /usr/local/var/lib/gvm/cert-data ];then mkdir -p /usr/local/var/lib/gvm/cert-data;fi
    chown gvm:gvm -R /usr/local/share/gvm
    chown gvm:gvm -R /usr/local/share/openvas
    chown gvm:gvm -R /usr/local/var/lib/gvm
    chown gvm:gvm -R /usr/local/var/lib/openvas
    chown gvm:gvm -R /usr/local/var/log/gvm
    chown gvm:gvm -R /usr/local/var/run
    chmod 770 -R /usr/local/var/lib/gvm
    chmod 770 -R /usr/local/var/lib/openvas
RUN echo '---------------------------------------------------------------------------------------------' && \    
    echo 'Updating NVTs' && \
    su -c 'if greenbone-nvt-sync &>/dev/null;then echo "nvt data synced via rsync";else echo "syncing nvt data via curl";greenbone-nvt-sync --curl &>/dev/null;fi;' gvm
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Updating SCAP data' && \
    su -c 'if greenbone-scapdata-sync &>/dev/null;then echo "scap data synced via rsync";else echo "syncing scap data via curl";greenbone-scapdata-sync --curl &>/dev/null;fi;' gvm
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Updating CERT data' && \
    su -c 'if greenbone-certdata-sync &>/dev/null;then echo "cert data synced via rsync";else echo "syncing cert data via curl";greenbone-certdata-sync --curl &>/dev/null;fi;' gvm
RUN echo '---------------------------------------------------------------------------------------------' && \
    echo 'Ensuring all libraries are linked and adding ospd directory' && \
    ldconfig && \
    mkdir /var/run/ospd
COPY start.sh /
RUN chmod +x /start.sh
CMD '/start.sh'
