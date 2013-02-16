#!/bin/bash

__namespace__() {

    INSTALLED=true
    INSTALLED_BY_DEFAULT=true

    check_packs 'sudo'

    if [[ $PACKS_INSTALLED = false ]]; then
        INSTALLED_BY_DEFAULT=false
        INSTALLED=false
        return
    fi

    local conf_file='/etc/sudoers'

    # Не требовать пароль при использовании sudo
    [[ ${!SUDO_OPTS[@]} =~ n|(nopasswd) ]] && {
    	grep '^%sudo ALL=(ALL) NOPASSWD: ALL$' $conf_file > /dev/null && {
            if [[ ${SUDO_OPTS[$BASH_REMATCH]} = no ]]; then
                INSTALLED=false
                return
            fi
        } || {
            if [[ ${SUDO_OPTS[$BASH_REMATCH]} != no ]]; then
                INSTALLED=false
                return
            fi
        }
    }
    
}; __namespace__
