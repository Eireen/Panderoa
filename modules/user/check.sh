#!/bin/bash

__namespace__() {

    check_installed_packs 'user'

    if [[ $USER_INSTALLED = false ]]; then
        return
    fi

    if [[ ${#USER_OPTS[@]} -eq 0 ]]; then
        return
    fi

    local req_opts=( 'l=login' )

    check_required_options USER "${req_opts[@]}"

    [[ ${!USER_OPTS[@]} =~ login ]] && {
        local login=${USER_OPTS['login']}
    } || {
        local login=${USER_OPTS['l']}
    }

    egrep "^$login:" /etc/passwd > /dev/null || {
        USER_INSTALLED=false
    }

}; __namespace__