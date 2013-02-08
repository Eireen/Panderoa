#!/bin/bash

check_installed_packs 'user'

if [[ $USER_INSTALLED = false ]]; then
	echo_installed
	exit
fi

local req_opts=( 'l=login' )

check_required_options USER "${req_opts[@]}"

[[ ${!USER_OPTS[@]} =~ login ]] && {
	local login=${USER_OPTS['login']}
} || {
	local login=${USER_OPTS['l']}
}

egrep "^$login" /etc/passwd > /dev/null || {
	USER_INSTALLED=false
}
