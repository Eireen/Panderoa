#!/bin/bash

__namespace__() {

    INSTALLED=true
    INSTALLED_BY_DEFAULT=true

    check_packs 'mysql'

    if [[ $PACKS_INSTALLED = false ]]; then
        INSTALLED_BY_DEFAULT=false
        INSTALLED=false
        return
    fi

    local conf_file='/etc/mysql/my.cnf'

    # Разрешить удаленный доступ
    [[ ${!MYSQL_OPTS[@]} =~ r|(remote-access) ]] && {
    	get_ip
    	grep "^bind-address = $IP$" $conf_file > /dev/null && {
    		if [[ ${MYSQL_OPTS[$BASH_REMATCH]} = no ]]; then
    			INSTALLED=false
    			return
    		fi
		} || {
			if [[ ${MYSQL_OPTS[$BASH_REMATCH]} != no ]]; then
    			INSTALLED=false
    			return
    		fi
		}
    }

}; __namespace__