#!/bin/bash

WORKDIR=/opt/push-server

SERVICE_CONFIG=push-server-multi

PUB_TMPL=push-server-pub-__PORT__.json
SUB_TMPL=push-server-sub-__PORT__.json
CONFIG_DIR=/etc/push-server
LOG_DIR=/var/log/push-server
[[ -z $PUSHROLE ]] && PUSHROLE="all"


SECURITY_KEY="${PUSH_SERVER_KEY}"

pushd $WORKDIR || exit 1

# config file
[[ ! -f /etc/default/$SERVICE_CONFIG ]] && \
    cp -fv etc/sysconfig/${SERVICE_CONFIG} /etc/default/${SERVICE_CONFIG}

# security key must be used in portal settings
[[ $(grep -v "^$\|^#" /etc/default/${SERVICE_CONFIG} | \
    grep -c "SECURITY_KEY") -eq 0 ]] && \
    echo "SECURITY_KEY=${SECURITY_KEY}" >> /etc/default/${SERVICE_CONFIG}

# run directory; there is pid-files
[[ $(grep -v "^$\|^#" /etc/default/${SERVICE_CONFIG} | \
    grep -c "RUN_DIR") -eq 0 ]] && \
    echo "RUN_DIR=/tmp/push-server" >> /etc/default/${SERVICE_CONFIG}

# tmp dir
[[ ! -d /tmp/push-server ]] && mkdir /tmp/push-server

# change bitrix user to root
sed -i "s/USER=bitrix/USER=root/" /etc/default/${SERVICE_CONFIG}

# debian vs redhat; compatibility
[[ ! -d /etc/sysconfig ]] && mkdir /etc/sysconfig
ln -sf /etc/default/${SERVICE_CONFIG} /etc/sysconfig

# if defined PUSHROLE; only one process is started
if [[ $PUSHROLE == "sub" ]]; then
    sed -i "s/ID_SUB=[0-9]\+/ID_SUB=0/" /etc/default/push-server-multi
elif [[ $PUSHROLE == "pub" ]]; then
    sed -i "s/ID_PUB=[0-9]\+/ID_PUB=0/" /etc/default/push-server-multi 
fi

# templates for pub and sub services
[[ ! -d /etc/push-server ]] && mkdir /etc/push-server

if [[ ! -f /etc/push-server/$PUB_TMPL ]]; then
    echo -n "Copy template: "
    cp -fv etc/push-server/$PUB_TMPL /etc/push-server/
fi
if [[ ! -f /etc/push-server/$SUB_TMPL ]]; then
    echo -n "Copy template: "
    cp -fv etc/push-server/$SUB_TMPL /etc/push-server/
fi

# service start script
cp -fv etc/init.d/push-server-multi /usr/local/bin
chmod 755 /usr/local/bin/push-server-multi

# generate configs
if [[ ( $PUSHROLE == "all" || $PUSHROLE == "sub")  && \
     ! -f /etc/push-server/push-server-sub-8010.json ]]; then
    /usr/local/bin/push-server-multi configs $PUSHROLE
elif [[ $PUSHROLE == "pub" && \
    ! -f /etc/push-server/push-server-pub-9010.json ]]; then
    /usr/local/bin/push-server-multi configs $PUSHROLE
fi


# start all services; withous changing user
/usr/local/bin/push-server-multi systemd_start $PUSHROLE

. /etc/default/${SERVICE_CONFIG}

while sleep 120; do
    if [[ $PUSHROLE == "pub" || $PUSHROLE == "all" ]]; then
        for n in $(seq 0 $ID_PUB); do
            port="901${n}"
            pidf=/tmp/push-server/pub-${port}.pid
            pidn=$(cat $pidf)
            ps ax -o pid |  grep "^\s*${pidn}$" >/dev/null 2>&1
            if [[ $? -gt 0 ]]; then
                echo "One of the processes [pub-${port}] has already exited."
                echo "Pid File: $pidf $(cat $pidf)"
                exit 1
            fi
        done
    fi
    if [[ $PUSHROLE == "sub" || $PUSHROLE == "all" ]]; then
        for n in $(seq 0 $ID_SUB) ; do
            port="801${n}"
            pidf=/tmp/push-server/sub-${port}.pid
            pidn=$(cat $pidf)
            ps ax -o pid |  grep "^\s*${pidn}$" >/dev/null 2>&1
            if [[ $? -gt 0 ]]; then
                echo "One of the processes [sub-${port}] has already exited."
                echo "Pid file: $pidf $(cat $pidf)"
                exit 1
            fi
        done
    fi
done

popd >/dev/null 2>&1
