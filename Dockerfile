# syntax=docker/dockerfile:1.14-labs

#-----------------------------------------------------
# Builder for rdiff-backup 2.0
#-----------------------------------------------------
FROM --platform=linux/arm64 python:3.7-bullseye AS builder-rdiff-backup-2.0

ENV TZ=UTC
ENV RDIFF_BACKUP_VERSION=2.0

# bullseye-security currently lists arm64 packages (git, libhtml-parser-perl, …)
# whose .debs 404 on the mirror. Use only the main archive for these builders.
RUN sed -i -E '/-security|-updates/d' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential librsync-dev libacl1-dev libattr1-dev git && \
    rm -rf /var/lib/apt/lists/*

RUN pip install tox

WORKDIR /opt/rdiff-backup

# .deb is produced by debbuild inside pyinstaller (same as 2.2), not dpkg-buildpackage.
RUN git clone https://gitlab.com/ikus-soft/rdiff-backup-build.git && \
    cd rdiff-backup-build && \
    cd $RDIFF_BACKUP_VERSION && \
    sed -i 's/architecture="amd64"/architecture="arm64"/g' rdiff-backup.spec && \
    tox -e pyinstaller && \
    mv dist/*.deb /opt/rdiff-backup-2.0.deb

#-----------------------------------------------------
# Builder for rdiff-backup 2.2
#-----------------------------------------------------
FROM --platform=linux/arm64 python:3.7-bullseye AS builder-rdiff-backup-2.2

ENV TZ=UTC
ENV RDIFF_BACKUP_VERSION=2.2

RUN sed -i -E '/-security|-updates/d' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential librsync-dev libacl1-dev libattr1-dev git && \
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
# Builder for minarca-server (from rdiffweb monorepo)
#-----------------------------------------------------
FROM --platform=linux/arm64 python:3.12-bookworm AS builder-minarca-server

ENV TZ=UTC
ENV MINARCA_SERVER_VERSION=7.2.1

RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-upgrade \
      git python3-dev python3-pip python3-setuptools && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install tox

WORKDIR /opt/rdiffweb

# From 7.0.0, minarca-server lives in the rdiffweb monorepo.
RUN --security=insecure git clone --depth 1 --branch $MINARCA_SERVER_VERSION https://gitlab.com/ikus-soft/rdiffweb.git . && \
    sed -i "s/architecture='amd64'/architecture='arm64'/g" minarca-server/packaging/minarca-server.spec && \
    tox -e pyinstaller && \
    mv dist/minarca-server_*.deb dist/minarca-server.deb

#-----------------------------------------------------
# Final image
#-----------------------------------------------------
FROM --platform=linux/arm64 debian:bookworm-slim

EXPOSE 8080
EXPOSE 22

VOLUME ["/etc/minarca/", "/backups", "/var/log/minarca/"]

ENV MINARCA_SERVER_HOST=0.0.0.0

COPY --from=builder-rdiff-backup-2.0 /opt/rdiff-backup-2.0.deb /tmp/rdiff-backup-2.0.deb
COPY --from=builder-rdiff-backup-2.2 /opt/rdiff-backup-2.2.deb /tmp/rdiff-backup-2.2.deb
COPY --from=builder-minarca-server /opt/rdiffweb/dist/minarca-server.deb /tmp/minarca-server.deb
COPY start.sh /opt/minarca-server/

RUN --security=insecure set -x && \
    apt update && \
    apt install -y --no-install-recommends ca-certificates curl gpg openssh-server && \
    dpkg -i /tmp/rdiff-backup-2.0.deb && \
    dpkg -i /tmp/rdiff-backup-2.2.deb && \
    dpkg -i --force-overwrite /tmp/minarca-server.deb && \
    awk '$5 >= 2048' /etc/ssh/moduli > /etc/ssh/moduli.new && \
    mv /etc/ssh/moduli.new /etc/ssh/moduli && \
    rm -rf /var/lib/apt/lists/* /etc/group- /etc/gshadow- /etc/shadow- /etc/ssh/ssh_host_* /tmp/*.deb && \
    mkdir -p /var/run/sshd && \
    chmod +x /opt/minarca-server/start.sh

CMD ["/opt/minarca-server/start.sh"]
