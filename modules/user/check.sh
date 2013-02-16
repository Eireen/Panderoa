#!/bin/bash

__namespace__() {

    INSTALLED=true
    INSTALLED_BY_DEFAULT=true

    check_packs 'user'

    if [[ $PACKS_INSTALLED = false ]]; then
        INSTALLED_BY_DEFAULT=false
        INSTALLED=false
        return
    fi

    local conf_file='/etc/passwd'

    [[ ${!USER_OPTS[@]} =~ l|(login) ]] && {
        local login=${USER_OPTS[$BASH_REMATCH]}
        grep "^$login:" $conf_file > /dev/null || {
            INSTALLED=false
            INSTALLED_BY_DEFAULT=false
            return
        }
    } || {
        echo "Required option 'login' is not found"
        exit 1
    }

    # Пользователь добавлен в группу sudo
    [[ ${!USER_OPTS[@]} =~ s|(sudoer) ]] && {
        if [[ ${USER_OPTS[$BASH_REMATCH]} != no ]]; then
            id $login | grep "sudo" > /dev/null || {
                INSTALLED=false
                INSTALLED_BY_DEFAULT=false
                return
            }
        fi
    }

}; __namespace__