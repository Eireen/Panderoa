#!/bin/bash

__namespace__() {
	
	INSTALLED=true
	INSTALLED_BY_DEFAULT=true

	local conf_file='/etc/ssh/sshd_config'

	check_installed_packs 'ssh'

	if [[ $PACKS_INSTALLED = false ]]; then
		INSTALLED_BY_DEFAULT=false
		INSTALLED=false
		return
	fi

	if [[ ${!SSH_OPTS[@]} =~ p|(port) ]]; then
		local port=${SSH_OPTS[$BASH_REMATCH]}
		if [[ -z `grep "^Port\s\+$port" $conf_file` ]]; then
			INSTALLED=false
			return
		fi
	fi

	if [[ ${!SSH_OPTS[@]} =~ f|forbid-root ]]; then
		if [[ -z `grep "^PermitRootLogin no" $conf_file` ]]; then
			INSTALLED=false
			return
		fi
	fi

}; __namespace__