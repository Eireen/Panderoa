#!/bin/bash

__namespace__() {

    [[ ${MODIFY[@]} =~ mysql ]] || {
        install_packs 'mysql'
        mysql_secure_installation
    }

    local conf_file='/etc/mysql/my.cnf'

    # Разрешить удаленный доступ
    [[ ${!MYSQL_OPTS[@]} =~ r|(remote-access) ]] && {
        if [[ ${MYSQL_OPTS[$BASH_REMATCH]} != no ]]; then
        	get_ip
            sed -e "s/^bind-address\s\+=\s\+[0-9\.]\+/bind-address = $IP/" -i $conf_file
            /etc/init.d/mysql restart
        fi
    }

}; __namespace__