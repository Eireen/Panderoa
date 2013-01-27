#!/bin/bash

# Checks required number of arguments
function check_num_args() {
    # $1 - required number of arguments
    # $2 - actual number of arguments
    # $3 - function name

    function print_message() {
    	# TODO: Plurality
        echo "Error: function $1() requires at least $2 arguments"
    }

	if [ $# -lt 3 ]; then
	    print_message $FUNCNAME $1
	    exit 1
	fi

	if [ $1 -gt $2 ]; then
        print_message $3 $1
		exit 1
	fi
}

# Checks if directory exists
function check_dir() {
    # $1 - path of directory
    # $2 - error message

    check_num_args 1 $# $FUNCNAME

	if [ ! -d "$1" ]; then
	    echo "${2-Error: directory \"`pwd`/$1\" does not exist!}"
		exit 1
	fi
}

# Checks if file exists
function check_file() {
    # $1 - path of file
    # $2 - error message

    check_num_args 1 $# $FUNCNAME

	if [ ! -f "$1" ]; then
	    echo "${2-Error: file \"`pwd`/$1\" does not exist!}"
		exit 1
	fi
}

function check_config() {
	for opt in "${!OPTIONS[@]}"; do
		if [[ $opt = 'conf' ]]; then
			local CONF_FILE="${OPTIONS[$opt]}"
			check_file $CONF_FILE
			. "$CONF_FILE"
			break
		fi
	done
}

# Requires config file
# Uses: OPTIONS, MODULES
function require_conf() {
	for opt in "${!OPTIONS[@]}"; do
		if [[ $opt = 'conf' ]]; then
			CONFIG="${OPTIONS[$opt]}"
			check_file $CONFIG
			. "$CONFIG"
			break
		fi
	done

	# При задании нескольких модулей конфиг обязателен
	if [[ ${#MODULES[@]} > 1 && -z $CONFIG ]]; then
		echo "If more than one module - config required"
		exit 1
	fi
}

# Overwrites settings from the config file by options from the console
function overwrite_options() {
    for opt in "${OPTIONS[@]}"; do
        if [[ $opt = 'conf' ]]; then
            continue
        fi
        
        VAR="${MODULES[0]}_opts"
    done
}