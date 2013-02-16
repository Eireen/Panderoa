#!/bin/bash

__namespace__() {

    [[ ${MODIFY[@]} =~ mongroup ]] || {
        install_packs 'mongroup'
        
        # Установка mon
        mkdir /tmp/mon 
        cd /tmp/mon 
        wget https://github.com/visionmedia/mon/archive/master.tar.gz
        tar -xzvf master.tar.gz
        rm master.tar.gz
        cd mon-master
        checkinstall --install=yes --pkgname=mon --default
        cd $MAIN_DIR
        rm -r /tmp/mon

        if [[ ! -d '/usr/local/bin' ]]; then
            mkdir '/usr/local/bin'
        fi

        mkdir -p /tmp/mongroup
        cd /tmp/mongroup
        wget 'https://github.com/jgallen23/mongroup/archive/master.tar.gz'
        tar -xzf 'master.tar.gz'
        cd mongroup-master
        checkinstall --install=yes --pkgname=mongroup --default

        cd $MAIN_DIR
        rm -r /tmp/mongroup
    }

}; __namespace__