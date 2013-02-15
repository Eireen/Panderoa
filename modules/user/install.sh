#!/bin/bash

__namespace__() {

    install_packs 'user'

    check_pack_status_by_apt 'whois'
    local purge_whois=false
    if [[ $PACK_INSTALLED = false ]]; then
        apt-get install -y whois > /dev/null
        purge_whois=true
    fi

    [[ ${!USER_OPTS[@]} =~ l|(login) ]] && {
        local login=${USER_OPTS[$BASH_REMATCH]}
    } || {
        echo "Required option 'login' is not found"
        exit 1
    }

    [[ ${!USER_OPTS[@]} =~ p|(password) ]] && {
        local password=${USER_OPTS[$BASH_REMATCH]}
    } || {
        echo "Required option 'password' is not found"
        exit 1
    }

    grep "^$login:" /etc/passwd >/dev/null && {
        echo "User '$login' already exists!"
        exit 1
    } || {
        local crypted_pass=`mkpasswd $password 12` # TODO: Random salt!
        useradd -m -s /bin/bash -p $crypted_pass $login && echo "User '$login' has been successfully added to system!" || {
            echo "Failed to add a user!"
            exit 1
        }
    }

    if [[ $purge_whois = true ]]; then
        apt-get purge -y whois > /dev/null
    fi

    # Добавить пользователя в группу 'sudo'
    [[ ${!USER_OPTS[@]} =~ s|(sudoer) ]] && {
        usermod -a -G sudo $login || {
            echo "Failed to add a user to the 'sudo' group!"
            exit 1
        }
    }

}; __namespace__