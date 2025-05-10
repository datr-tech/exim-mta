FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update -y \
  && apt install \
    exim4-base \
    exim4-config \
    exim4-daemon-heavy \
    gnutls-bin \
    sqlite3 -y \
  && apt clean -y \
  && groupadd mail -f \
  && useradd -m \
    -d /home/admin \
    -g mail \
    -s /usr/bin/bash \
    admin \
  && useradd -m \
    -d /home/${DOCKER_MAILDIR_NAME} \
    -g mail \
    -s /usr/bin/bash \
    ${DOCKER_EXIM_PASS} \
  && echo "${DOCKER_EXIM_PASS}:${DOCKER_DOCKER_EXIM_PASS}" | chpasswd

USER Debian-exim:mail

COPY ./conf/ /etc/exim4/
COPY ./conf/aliases /etc/
COPY ./conf/exim4.conf /etc/

RUN /usr/sbin/update-exim4.conf

ENTRYPOINT [ "/usr/sbin/exim4", "-bd", "-d" ]
