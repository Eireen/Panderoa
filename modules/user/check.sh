#!/bin/bash

INSTALLED=false

local req_opts=( 'l=login' )

check_required_options USER "${req_opts[@]}"

[[ ${USER_OPTS[@]} =~ login ]] && {
	local login=USER_OPTS['login']	
} || {
	local login=USER_OPTS['l']
}

grep $login /etc/passwd > /dev/null && {
	INSTALLED=true
}