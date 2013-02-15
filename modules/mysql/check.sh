#!/bin/bash

__namespace__() {

	INSTALLED=true
	INSTALLED_BY_DEFAULT=true

	check_packs 'mysql'

	if [[ $PACKS_INSTALLED = false ]]; then
		INSTALLED_BY_DEFAULT=false
		INSTALLED=false
		return
	fi

}; __namespace__