#!/bin/bash

__namespace__() {

    require_packs 'user'

    install_packs

    local result=`aptitude search whois`
    local status=${result:0:1}
    if [[ $status = 'p' || $status = 'c' ]]; then
        apt-get install -y whois > /dev/null
    fi

    # TODO: DRY
    [[ ${!USER_OPTS[@]} =~ 'login' ]] && {
        local login=${USER_OPTS['login']}
    } || {
        local login=${USER_OPTS['l']}
    }

    [[ ${!USER_OPTS[@]} =~ 'password' ]] && {
        local password=${USER_OPTS['password']}
    } || {
        local password=${USER_OPTS['p']}
    }

    # Script to add a user to Linux system
    egrep "^$login" /etc/passwd >/dev/null && {
        echo "User '$login' already exists!"
        exit 1
    } || {
        local crypted_pass=`mkpasswd $password 12`
        useradd -m -p $crypted_pass $login && echo "User '$login' has been successfully added to system!" || {
            echo "Failed to add a user!"
            exit 1
        }
    }

    # Add user to 'sudo' group (if option '-s' is specified)
    : 'if [[ ${!USER_OPTS[@]} =~ s ]]; then
        gpasswd -a $login sudo
    fi'

    if [[ $status = 'p' || $status = 'c' ]]; then
        apt-get purge -y whois > /dev/null
    fi

}; __namespace__