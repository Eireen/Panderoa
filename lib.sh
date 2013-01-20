#!/bin/sh

# Confirmation from user
# Parameters: 
# 1 - question
# 2 - if_not_sure
function confirm() {
	if [[ $# -lt 1 ]]; then
		echo 'Error: function confirm() requires at least 1 parameter'
		exit 1
	fi
	read -n 1 -p "$1" SURE 
		[[ "$SURE" = y ]] || {
			echo 
			if [[ $# -gt 1 ]]; then
				echo $2
			fi
			exit 0
		}
		echo "" 1>&2
}