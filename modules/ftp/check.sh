#!/bin/bash

__namespace__() {

    INSTALLED=true
    INSTALLED_BY_DEFAULT=true

    check_packs 'ftp'

    if [[ $PACKS_INSTALLED = false ]]; then
        INSTALLED_BY_DEFAULT=false
        INSTALLED=false
        return
    fi

    local conf_file='/etc/vsftpd.conf'

    # Выключить анонимный доступ к FTP-серверу
    [[ ${!FTP_OPTS[@]} =~ a|(disable-anonymous) ]] && {
    	grep '^anonymous_enable=NO$' $conf_file > /dev/null && {
    		if [[ ${FTP_OPTS[$BASH_REMATCH]} = no ]]; then
    			INSTALLED=false
    			return
    		fi
		} || {
			if [[ ${FTP_OPTS[$BASH_REMATCH]} != no ]]; then
    			INSTALLED=false
    			return
    		fi
		}
    }

    # Дать возможность заходить на сервер локально
    [[ ${!FTP_OPTS[@]} =~ l|(enable-local) ]] && {
    	grep '^local_enable=YES$' $conf_file > /dev/null && {
    		if [[ ${FTP_OPTS[$BASH_REMATCH]} = no ]]; then
    			INSTALLED=false
    			return
    		fi
		} || {
			if [[ ${FTP_OPTS[$BASH_REMATCH]} != no ]]; then
    			INSTALLED=false
    			return
    		fi
		}
    }

    # Разрешить закидывать файлы на сервер
    [[ ${!FTP_OPTS[@]} =~ w|(enable-write) ]] && {
    	grep '^write_enable=YES$' $conf_file > /dev/null && {
    		if [[ ${FTP_OPTS[$BASH_REMATCH]} = no ]]; then
    			INSTALLED=false
    			return
    		fi
		} || {
			if [[ ${FTP_OPTS[$BASH_REMATCH]} != no ]]; then
    			INSTALLED=false
    			return
    		fi
		}
    }

}; __namespace__