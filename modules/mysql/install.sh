#!/bin/bash

__namespace__() {

    install_packs 'mysql'

    mysql_secure_installation

    local conf_file='/etc/mysql/my.cnf'

    # Разрешить удаленный доступ
    [[ ${!MYSQL_OPTS[@]} =~ r|(remote-access) ]] && {
        if [[ ${MYSQL_OPTS[$BASH_REMATCH]} != no ]]; then
        	local ip=`ip -4 a l dev eth1  | grep inet | awk '{ print $2 }'`
        	local pos=`expr index $ip /`
        	[[ $pos -ne 0 ]] && {
        		ip=${ip:0:(($pos-1))}
        	}
            sed -e "s/^bind-address\s\+=\s\+[0-9\.]\+/bind-address = $ip/" -i $conf_file
            service mysqld restart
        fi
    }

}; __namespace__