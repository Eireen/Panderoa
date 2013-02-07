#!/bin/bash

require_packs 'user'

install_packs

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


