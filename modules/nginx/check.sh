#!/bin/bash

__namespace__() {

	check_installed_packs 'nginx'

	if [[ $NGINX_INSTALLED = true ]]; then
		check_installed_pack_by_dpkg 'nginx'
		NGINX_INSTALLED=$PACK_INSTALLED
	fi

}; __namespace__