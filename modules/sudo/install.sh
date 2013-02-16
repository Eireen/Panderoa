#!/bin/bash

__namespace__() {

    [[ ${MODIFY[@]} =~ sudo ]] || {
        install_packs 'sudo'
    }

    local conf_file='/etc/sudoers'

    # Не требовать пароль при использовании sudo
    [[ ${!SUDO_OPTS[@]} =~ n|(nopasswd) ]] && {
        local replacement="^#\?\s*%sudo\s\+ALL=.\+"
        if [[ ${SUDO_OPTS[$BASH_REMATCH]} != no ]]; then
            sed -e "s/$replacement/%sudo ALL=(ALL) NOPASSWD: ALL/" -i $conf_file
        else
            sed -e "s/$replacement/%sudo ALL=(ALL) ALL/" -i $conf_file
        fi
    }

}; __namespace__