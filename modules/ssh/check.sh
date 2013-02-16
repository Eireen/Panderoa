#!/bin/bash

__namespace__() {
    
    INSTALLED=true
    INSTALLED_BY_DEFAULT=true

    check_packs 'ssh'

    if [[ $PACKS_INSTALLED = false ]]; then
        INSTALLED_BY_DEFAULT=false
        INSTALLED=false
        return
    fi

    local conf_file='/etc/ssh/sshd_config'

    if [[ ${!SSH_OPTS[@]} =~ p|(port) ]]; then
        local port=${SSH_OPTS[$BASH_REMATCH]}
        grep "^Port\s\+$port$" $conf_file > /dev/null || {
            INSTALLED=false
            return
        }
    fi

    [[ ${!SSH_OPTS[@]} =~ f|forbid-root ]] && {
        grep '^PermitRootLogin no$' $conf_file > /dev/null && {
            if [[ ${SSH_OPTS[$BASH_REMATCH]} = no ]]; then
                INSTALLED=false
                return
            fi
        } || {
            if [[ ${SSH_OPTS[$BASH_REMATCH]} != no ]]; then
                INSTALLED=false
                return
            fi
        }
    }

}; __namespace__