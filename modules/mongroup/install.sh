#!/bin/bash

__namespace__() {

    [[ ${MODIFY[@]} =~ mongroup ]] || {
        install_packs 'mongroup'
        
        if [[ ! -d '/usr/local/bin' ]]; then
            mkdir '/usr/local/bin'
        fi

        # Установка mon
        mkdir /tmp/mon 
        cd /tmp/mon 
        wget --no-check-certificate https://github.com/visionmedia/mon/archive/master.tar.gz
        tar -xzvf master.tar.gz
        rm master.tar.gz
        cd mon-master
        checkinstall --install=yes --pkgname=mon --default
        cd $MAIN_DIR
        rm -r /tmp/mon

        mkdir -p /tmp/mongroup
        cd /tmp/mongroup
        wget --no-check-certificate 'https://github.com/jgallen23/mongroup/archive/master.tar.gz'
        tar -xzf 'master.tar.gz'
        cd mongroup-master
        checkinstall --install=yes --pkgname=mongroup --default

        cd $MAIN_DIR
        rm -r /tmp/mongroup
    }

}; __namespace__