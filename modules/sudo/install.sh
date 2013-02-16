#!/bin/bash

__namespace__() {

    [[ ${MODIFY[@]} =~ sudo ]] || {
        install_packs 'sudo'
    }

    local conf_file='/etc/sudoers'

    # Не требовать пароль при использовании sudo
    [[ ${!SUDO_OPTS[@]} =~ n|(nopasswd) ]] && {
        if [[ ${SUDO_OPTS[$BASH_REMATCH]} != no ]]; then
            sed -e "s/^#\?\s*%sudo\s\+ALL=.\+/%sudo ALL=(ALL) NOPASSWD: ALL/" -i $conf_file
        fi
    }

}; __namespace__