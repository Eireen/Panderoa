#!/bin/bash

__namespace__() {

    [[ ${MODIFY[@]} =~ ftp ]] || {
        install_packs 'ftp'
    }

    local conf_file='/etc/vsftpd.conf'

    # Выключить анонимный доступ к FTP-серверу
    [[ ${!FTP_OPTS[@]} =~ a|(disable-anonymous) ]] && {
        if [[ ${FTP_OPTS[$BASH_REMATCH]} != no ]]; then
            sed -e "s/^anonymous_enable=YES/anonymous_enable=NO/" -i $conf_file
        fi
    }

    # Дать возможность заходить на сервер локально
    [[ ${!FTP_OPTS[@]} =~ l|(enable-local) ]] && {
        if [[ ${FTP_OPTS[$BASH_REMATCH]} != no ]]; then
            sed -e "s/^#\?local_enable=YES/local_enable=YES/" -i $conf_file
        fi
    }

    # Разрешить закидывать файлы на сервер
    [[ ${!FTP_OPTS[@]} =~ w|(enable-write) ]] && {
        if [[ ${FTP_OPTS[$BASH_REMATCH]} != no ]]; then
            sed -e "s/^#\?write_enable=YES/write_enable=YES/" -i $conf_file
        fi
    }

    /etc/init.d/vsftpd restart

}; __namespace__