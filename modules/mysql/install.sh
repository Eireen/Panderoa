#!/bin/bash

__namespace__() {

    [[ ${MODIFY[@]} =~ mysql ]] || {
        install_packs 'mysql'
        mysql_secure_installation
    }

    local conf_file='/etc/mysql/my.cnf'

    # Разрешить удаленный доступ
    [[ ${!MYSQL_OPTS[@]} =~ r|(remote-access) ]] && {
        local param='bind-address'
        if [[ ${MYSQL_OPTS[$BASH_REMATCH]} != no ]]; then
            get_ip
        	local value=$IP
        else
            local value='127.0.0.1'
        fi
        sed -e "s/^$param\s\+=\s\+[0-9\.]\+/$param = $value/" -i $conf_file
        /etc/init.d/mysql restart
    }

}; __namespace__