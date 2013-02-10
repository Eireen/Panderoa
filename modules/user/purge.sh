#!/bin/bash

require_packs 'user'

packs_to_remove 'user'

purge_packs

[[ ${!USER_OPTS[@]} =~ 'login' ]] && {
    local login=${USER_OPTS['login']}
} || {
    local login=${USER_OPTS['l']}
}

userdel -r $login

local exit_code=$?

if [ $exit_code -eq 0 ]; then
	echo "User $login was successfully removed from system."
	exit $exit_code
else
	echo "Failed to remove a user!"
	exit $exit_code
fi