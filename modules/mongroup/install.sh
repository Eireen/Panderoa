#!/bin/bash

__namespace__() {

    install_packs 'mongroup'

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

}; __namespace__