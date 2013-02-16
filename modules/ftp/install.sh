#!/bin/bash

__namespace__() {

    [[ ${MODIFY[@]} =~ ftp ]] || {
        install_packs 'ftp'
    }

    local conf_file='/etc/vsftpd.conf'

    # Выключить анонимный доступ к FTP-серверу
    [[ ${!FTP_OPTS[@]} =~ a|(disable-anonymous) ]] && {
        local param='anonymous_enable'
        if [[ ${FTP_OPTS[$BASH_REMATCH]} != no ]]; then
            local value="NO"
        else
            local value="YES"
        fi
        sed -e "s/^$param=[YESNO]\+/$param=$value/" -i $conf_file
    }

    # Дать возможность заходить на сервер локально
    [[ ${!FTP_OPTS[@]} =~ l|(enable-local) ]] && {
        local param='local_enable'
        if [[ ${FTP_OPTS[$BASH_REMATCH]} != no ]]; then
            sed -e "s/^#\?$param=YES/$param=YES/" -i $conf_file
        else
            sed -e "s/^$param=YES/#$param=YES/" -i $conf_file
        fi
    }

    # Разрешить закидывать файлы на сервер
    [[ ${!FTP_OPTS[@]} =~ w|(enable-write) ]] && {
        local param='write_enable'
        if [[ ${FTP_OPTS[$BASH_REMATCH]} != no ]]; then
            sed -e "s/^#\?$param=YES/$param=YES/" -i $conf_file
        else
            sed -e "s/^$param=YES/#$param=YES/" -i $conf_file
        fi
    }

    /etc/init.d/vsftpd restart

}; __namespace__