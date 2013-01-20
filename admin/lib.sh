#!/bin/bash

# Checks required number of arguments
# 1 - required number of arguments
# 2 - actual number of arguments
# 3 - error message
# 4 - usage message
function checkNumArgs() {
	if [[ $# -lt 2 ]]; then
		echo "Error: function checkNumArgs() requires at least 2 arguments"
		exit 1
	fi
	if [[ $1 -gt $2 ]]; then
		if [[ $# -gt 2 ]]; then
			echo "$3"
		else
			echo "Invalid number of arguments: $2, expected $1"
		fi
		if [[ $# -gt 3 ]]; then
			echo "$4"
		fi
		exit 1
	fi
}

# Confirmation from user
# Parameters: 
# 1 - question
# 2 - message printing if not sure
function confirm() {
	checkNumArgs 1 $# "Error: function confirm() requires at least 1 argument"
	read -n 1 -p "$1" SURE 
		[[ "$SURE" = y ]] || {
			echo 
			if [[ $# -gt 1 ]]; then
				echo "$2"
			fi
			exit 0
		}
		echo "" 1>&2
}

# Checks if directory exists
# Parameters:
# 1 - directory
# 2 - message printing if not exist
function checkDir() {
	checkNumArgs 1 $# "Error: function checkDir() requires at least 1 argument"
	if [ ! -d "$1" ]; then
		if [[ $# -gt 1 ]]; then
			echo "$2"
		else
			echo "Directory $1 doesn't exist"
		fi
		exit 1
	fi
}

# Checks if file exists
# Parameters:
# 1 - file
# 2 - message printing if not exist
function checkFile() {
	checkNumArgs 1 $# "Error: function checkFile() requires at least 1 argument"
	if [ ! -f "$1" ]; then
		if [[ $# -gt 1 ]]; then
			echo "$2"
		else
			echo "File $1 doesn't exist"
		fi
		exit 1
	fi
}