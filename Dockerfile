FROM ubuntu:24.04

ARG EXIM_MTA_ADMIN
ARG EXIM_MTA_ADMIN_DIR
ARG EXIM_MTA_ADMIN_GRP
ARG EXIM_MTA_ADMIN_SHELL
ARG EXIM_MTA_AUTHOR
ARG EXIM_MTA_CONF
ARG EXIM_MTA_CONF_ALIASES
ARG EXIM_MTA_CONF_ETC
ARG EXIM_MTA_GRP
ARG EXIM_MTA_USER
ARG EXIM_MTA_USER_DIR
ARG EXIM_MTA_USER_GRP
ARG EXIM_MTA_USER_PASS
ARG EXIM_MTA_USER_SHELL
ARG EXIM_MTA_USER_SYS

LABEL authors=$EXIM_MTA_AUTHOR
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update -y \
  && apt install \
    exim4-base \
    exim4-config \
    exim4-daemon-heavy \
    gnutls-bin \
    sqlite3 -y \
  && apt clean -y \
  && groupadd $EXIM_MTA_GRP -f \
  && useradd -m \
    -d $EXIM_MTA_ADMIN_DIR \
    -g $EXIM_MTA_ADMIN_GRP \
    -s $EXIM_MTA_ADMIN_SHELL \
    $EXIM_MTA_ADMIN \
  && useradd -m \
    -d $EXIM_MTA_USER_DIR \
    -g $EXIM_MTA_USER_GRP \
    -s $EXIM_MTA_USER_SHELL \
    $EXIM_MTA_USER \
  && echo "$EXIM_MTA_USER:$EXIM_MTA_USER_PASS" | chpasswd

USER $EXIM_MTA_USER_SYS

COPY $EXIM_MTA_CONF /etc/exim4/
COPY $EXIM_MTA_CONF_ALIASES /aliases/
COPY $EXIM_MTA_CONF_ALIASES /etc/
COPY $EXIM_MTA_CONF_ETC /etc/

RUN /usr/sbin/update-exim4.conf

ENTRYPOINT [ "/usr/sbin/exim4", "-bd", "-d" ]
