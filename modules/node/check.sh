#!/bin/bash

__namespace__() {

	check_installed_packs 'node'

	if [[ $NODE_INSTALLED = true ]]; then
		check_installed_pack_by_dpkg 'nodejs'
		NODE_INSTALLED=$PACK_INSTALLED
	fi

}; __namespace__