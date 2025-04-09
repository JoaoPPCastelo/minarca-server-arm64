# syntax=docker/dockerfile:1.3-labs

#-----------------------------------------------------
# Builder for rdiff-backup 1.2
#-----------------------------------------------------
FROM --platform=arm64 python:2.7-buster AS builder-rdiff-backup-1.2

ENV TZ=UTC
ENV RDIFF_BACKUP_VERSION=1.2

RUN apt update && \
    apt -y --no-install-recommends install build-essential debhelper devscripts librsync-dev libacl1-dev libattr1-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip install tox

WORKDIR /opt/rdiff-backup

RUN git clone https://gitlab.com/ikus-soft/rdiff-backup-build.git && \
    cd rdiff-backup-build && \
    cd $RDIFF_BACKUP_VERSION && \
    #sed -i 's/architecture="amd64"/architecture="arm64"/g' rdiff-backup.spec && \
    tox -e pyinstaller && \
    apt-get build-dep -y . && \
    dpkg-buildpackage -b && \
    rm ../*dbgsym*.deb && \
    mv ../*.deb /opt/rdiff-backup-1.2.deb

#-----------------------------------------------------
# Builder for rdiff-backup 2.0
#-----------------------------------------------------
FROM --platform=arm64 python:3.7-buster AS builder-rdiff-backup-2.0

ENV TZ=UTC
ENV RDIFF_BACKUP_VERSION=2.0

RUN apt update && \
    apt -y --no-install-recommends install build-essential debhelper devscripts librsync-dev libacl1-dev libattr1-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip install tox

WORKDIR /opt/rdiff-backup

RUN git clone https://gitlab.com/ikus-soft/rdiff-backup-build.git && \
    cd rdiff-backup-build && \
    cd $RDIFF_BACKUP_VERSION && \
    #sed -i 's/architecture="amd64"/architecture="arm64"/g' rdiff-backup.spec && \
    tox -e pyinstaller && \
    apt-get build-dep -y . && \
    dpkg-buildpackage -b && \
    rm ../*dbgsym*.deb && \
    mv ../*.deb /opt/rdiff-backup-2.0.deb

#-----------------------------------------------------
# Builder for rdiff-backup 2.2
#-----------------------------------------------------
FROM --platform=arm64 python:3.7-buster AS builder-rdiff-backup-2.2

ENV TZ=UTC
ENV RDIFF_BACKUP_VERSION=2.2

RUN apt update && \
    apt -y --no-install-recommends install build-essential librsync-dev libacl1-dev libattr1-dev librsync-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip install tox

WORKDIR /opt/rdiff-backup

RUN git clone https://gitlab.com/ikus-soft/rdiff-backup-build.git && \
    cd rdiff-backup-build && \
    cd $RDIFF_BACKUP_VERSION && \
    sed -i 's/architecture="amd64"/architecture="arm64"/g' rdiff-backup.spec && \
    tox -e pyinstaller && \
    mv dist/*.deb /opt/rdiff-backup-2.2.deb
    
#-----------------------------------------------------
# Builder for minarca-server
#-----------------------------------------------------
FROM --platform=arm64 python:3.12-bullseye AS builder-minarca-server

ENV TZ=UTC
ENV MINACRCA_SERVER_VERSION=6.1.0a3

RUN apt update && \
    apt -y --no-install-recommends install python3-dev python3-pip python3-setuptools && \
    rm -rf /var/lib/apt/lists/*
    
RUN pip3 install tox

WORKDIR /opt/minarca-server

RUN --security=insecure git clone https://gitlab.com/ikus-soft/minarca-server.git && \
    cd minarca-server && \
    git checkout $MINACRCA_SERVER_VERSION && \
    sed -i "s/architecture='amd64'/architecture='arm64'/g" packaging/minarca-server.spec && \
    TOXENV=py3 tox && \
    TOXENV=pyinstaller tox && \
    mv dist/minarca-server_*.deb dist/minarca-server.deb 

#-----------------------------------------------------
# Final image
#-----------------------------------------------------
FROM --platform=arm64 debian:bookworm-slim

EXPOSE 8080
EXPOSE 22

VOLUME ["/etc/minarca/", "/backups", "/var/log/minarca/"]

ENV MINARCA_SERVER_HOST=0.0.0.0

COPY --from=builder-rdiff-backup-1.2 /opt/rdiff-backup-1.2.deb /opt/rdiff-backup/rdiff-backup-1.2.deb
COPY --from=builder-rdiff-backup-2.0 /opt/rdiff-backup-2.0.deb /opt/rdiff-backup/rdiff-backup-2.0.deb
COPY --from=builder-rdiff-backup-2.2 /opt/rdiff-backup-2.2.deb /opt/rdiff-backup/rdiff-backup-2.2.deb
COPY --from=builder-minarca-server /opt/minarca-server/minarca-server/dist /opt/minarca-server/
COPY --from=builder-minarca-server /opt/minarca-server/minarca-server/docker/start.sh /opt/minarca-server/

RUN set -x && \
    apt update  && \
    apt install -y --no-install-recommends ca-certificates curl gpg rdiff-backup && \
    apt install -y --no-install-recommends /opt/rdiff-backup/rdiff-backup-1.2.deb && \
    apt install -y --no-install-recommends /opt/rdiff-backup/rdiff-backup-2.0.deb && \
    apt install -y --no-install-recommends /opt/rdiff-backup/rdiff-backup-2.2.deb && \
    apt install -y --no-install-recommends /opt/minarca-server/minarca-server.deb
    # awk '$5 >= 2048' /etc/ssh/moduli > /etc/ssh/moduli.new && \
    # mv /etc/ssh/moduli.new /etc/ssh/moduli && \
    # rm -rf /var/lib/apt/lists/* /etc/group- /etc/gshadow- /etc/shadow- /etc/ssh/ssh_host_* && \
    # mkdir -p /var/run/sshd && \
    # chmod +x /start.sh

# CMD ["/start.sh"]