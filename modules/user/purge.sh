#!/bin/bash

__namespace__() {

	purge_packs 'user'

	[[ ${!USER_OPTS[@]} =~ l|(login) ]] && {
        local login=${USER_OPTS[$BASH_REMATCH]}
    } || {
        echo "Required option 'login' is not found"
        exit 1
    }

	userdel -r $login && {
		echo "User $login was successfully removed from system."
		exit $exit_code
	} || {
		echo "Failed to remove a user!"
		exit $exit_code
	}

}; __namespace__