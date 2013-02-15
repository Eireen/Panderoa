#!/bin/bash

__namespace__() {

    INSTALLED=true
    INSTALLED_BY_DEFAULT=true

    check_packs 'nginx'

    if [[ $PACKS_INSTALLED = false ]]; then
        INSTALLED_BY_DEFAULT=false
        INSTALLED=false
        return
    fi

    check_pack_status_by_dpkg 'nginx'

    if [[ $PACK_INSTALLED = false ]]; then
        INSTALLED_BY_DEFAULT=false
        INSTALLED=false
        return
    fi

    if [[ ${!NGINX_OPTS[@]} =~ a|(auth) ]]; then
        : 'local port=${NGINX_OPTS[$BASH_REMATCH]}
        if [[ -z `grep "^Port\s\+$port" $conf_file` ]]; then
            INSTALLED=false
            return
        fi'
    fi

    if [[ ${!NGINX_OPTS[@]} =~ g|(gzip-static) ]]; then
        : 'local port=${NGINX_OPTS[$BASH_REMATCH]}
        if [[ -z `grep "^Port\s\+$port" $conf_file` ]]; then
            INSTALLED=false
            return
        fi'
    fi

}; __namespace__