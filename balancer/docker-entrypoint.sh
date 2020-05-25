#!/bin/bash
# https://github.com/sameersbn/docker-nginx/blob/master/entrypoint.sh
set -e

[[ $DEBUG == true ]] && set -x

configure_ssl(){
    if [[ ! -f /etc/nginx/dhparam.pem ]]; then
        openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 2048
    fi

    if [[ -z $DOMAINS ]]; then
        return 1
    fi

    DOMAINS_LIST=$(echo "$DOMAINS" | sed -e 's/,/ /g')
    FIRST_DOMAIN=$(echo "$DOMAINS" | awk -F',' '{print $1}')
    if [[ ! -f /etc/dehydrated/domains.txt ]]; then
        # start nginx (80 port)
        nginx
        if [[ $DEBUG == true ]]; then
            ps -ef | grep nginx
            ss -lnp | grep nginx
        fi

        echo "$DOMAINS_LIST" > /etc/dehydrated/domains.txt

        /usr/bin/dehydrated --register --accept-terms
        if [[ $? -gt 0 ]]; then
            echo "ERROR: dehydrated accept terms."
            return 1
        fi

        # request or update certificate
        /usr/bin/dehydrated -c
        if [[ $? -gt 0 ]]; then
            echo "ERROR: dehydrated request certificate failed."
            return 1
        fi

        if [[ ! -d /var/lib/dehydrated/certs/$FIRST_DOMAIN ]]; then
            echo "ERROR: there is no certificate directory"
            return 1
        fi

        # kill current running process
        kill $(cat /run/nginx.pid)
        if [[ $DEBUG == true ]]; then
            ps -ef | grep nginx
            ss -lnp | grep nginx
        fi
    fi
    
    # update https config
    if [[ ! -f /etc/nginx/vhosts/https.conf ]]; then
        cat /etc/nginx/vhosts/https.conf.disabled | \
            sed -e "s/__DOMAINS__/$DOMAINS_LIST/g; \
            s/__DOMAIN__/$FIRST_DOMAIN/g" > /etc/nginx/vhosts/https.conf

        rm -f /etc/nginx/vhosts/https.conf.disabled
    fi

    # start cron file
    cron
    echo "Start cron daemon for dehydrated updates"

    # update HOOK config
    if [[ $(grep -v '^$\|^#' /etc/dehydrated/config | grep -c "HOOK=") -eq 0 ]]; then
        echo "HOOK=/etc/dehydrated/hook.sh" >> /etc/dehydrated/config
    fi
}

# allow arguments to be passed to nginx
if [[ ${1:0:1} = '-' ]]; then
    EXTRA_ARGS="$@"
    set --
elif [[ ${1} == nginx || ${1} == $(which nginx) ]]; then
    EXTRA_ARGS="${@:2}"
    set --
fi

# configure dehydrated and update nginx config
configure_ssl

# default behaviour is to launch nginx
if [[ -z ${1} ]]; then
    echo "Starting nginx..."
    exec $(which nginx) -g "daemon off;" ${EXTRA_ARGS}
else
    exec "$@"
fi
