#!/bin/bash
# https://github.com/sameersbn/docker-nginx/blob/master/entrypoint.sh
set -e

[[ $DEBUG == true ]] && set -x

configure_ssl(){
    if [[ ! -f /etc/nginx/dhparam.pem ]]; then
        openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 2048
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

# default behaviour is to launch nginx
if [[ -z ${1} ]]; then
    echo "Starting nginx..."
    exec $(which nginx) -g "daemon off;" ${EXTRA_ARGS}
else
    exec "$@"
fi
