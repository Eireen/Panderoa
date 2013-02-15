#!/bin/bash

__namespace__() {

	require_packs 'mongroup'
	install_packs

	ORIGIN_DIR=`pwd`

	if [[ ! -d '/usr/local/bin' ]]; then
		mkdir '/usr/local/bin'
	fi

	mkdir -p /tmp/mongroup
	cd /tmp/mongroup
	wget 'https://github.com/jgallen23/mongroup/archive/master.tar.gz'
	tar -xzf 'master.tar.gz'
	cd mongroup-master
	checkinstall --install=yes --pkgname=mongroup --default

	cd $ORIGIN_DIR
	rm -r /tmp/mongroup

}; __namespace__