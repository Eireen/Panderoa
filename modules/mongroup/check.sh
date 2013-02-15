#!/bin/bash

__namespace__() {

	INSTALLED=true
	INSTALLED_BY_DEFAULT=true

	check_packs 'mongroup'

	if [[ $PACKS_INSTALLED = false ]]; then
		INSTALLED_BY_DEFAULT=false
		INSTALLED=false
		return
	fi

	check_pack_status_by_dpkg 'mongroup'

	if [[ $PACK_INSTALLED = false ]]; then
		INSTALLED_BY_DEFAULT=false
		INSTALLED=false
		return
	fi

}; __namespace__