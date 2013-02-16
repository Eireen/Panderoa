#!/bin/bash

__namespace__() {

    [[ ${MODIFY[@]} =~ node ]] || {
        install_packs 'node'

        rm -rf /tmp/node-install
        mkdir /tmp/node-install
        cd /tmp/node-install

        wget http://nodejs.org/dist/node-latest.tar.gz

        tar -xzf node-latest.tar.gz
        rm node-latest.tar.gz
        cd node-v*
        ./configure && make && checkinstall --install=yes --pkgname=nodejs --default
        
        cd $MAIN_DIR
        rm -rf /tmp/node-install
    }

}; __namespace__