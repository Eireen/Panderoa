#!/bin/bash

# Determines whether the number of arguments a function requires
# $1 - required number of arguments
# $2 - actual number of arguments
# $3 - function name
function check_num_args() {

    function print_message() {
        echo "Error: function $1() requires at least $2 arguments"
    }

    if [[ $# -lt 3 ]]; then
        print_message $FUNCNAME $1
        exit 1
    fi

    if [[ $1 -gt $2 ]]; then
        print_message $3 $1
        exit 1
    fi
}

# Determines whether the specified path refers to an existing directory
# $1 - the path to test
# $2 - the error message
# exit code: 0 if path refers to an existing directory; otherwise, 1
function check_dir() {
    check_num_args 1 $# $FUNCNAME

    if [[ ! -d "$1" ]]; then
        echo "${2-Error: directory \"$1\" does not exist!}"
        exit 1
    fi
}

# Determines whether the specified path refers to an existing file
# $1 - the path to test
# $2 - the error message
# exit code: 0 if path refers to an existing file; otherwise, 1
function check_file() {
    check_num_args 1 $# $FUNCNAME

    if [[ ! -f "$1" ]]; then
        echo "${2-Error: file \"$1\" does not exist!}"
        exit 1
    fi
}

# Determines whether the specified object exists as an element in an Array object
# $1 - the array to search
# $2 - the object to find in the array
# return: 0 if the specified object exists as an element in the array; otherwise, 1
function contains() {
    check_num_args 2 $# $FUNCNAME

    local array="$1[@]"; declare -a array=("${!array}")

    for item in "${array[@]}"; do
        if [[ $2 == $item ]]; then
            return 0
        fi
    done

    return 1
}

function array_into_buffer() {
    check_num_args 1 $# $FUNCNAME

    local array="$1[@]"; declare -a array=("${!array}")

    for item in "${!array[@]}"; do
        BUFFER["$item"]="${array[$item]}"
    done
}

function buffer_into_array() {
    check_num_args 1 $# $FUNCNAME

    declare -a array

    for item in "${!BUFFER[@]}"; do
        array["$item"]="${BUFFER[$item]}"
    done

    eval "$1=(${array[@]})"
}

# Clear the list of repetitive items
# $1 - list
function clear_from_repetitives() {
    check_num_args 1 $# $FUNCNAME

    local array="$1[@]"; declare -a array=("${!array}")

    local i=0
    while [[ $i -lt "${#array[@]}" ]]; do
        local j=0

        while [[ $j -lt "${#array[@]}" ]]; do
            if [[ $i -ne $j ]] && [[ ${array[$i]} == ${array[$j]} ]]; then
                (( max = i > j ? i : j ))

                # Remove a module with the largest index
                array=( ${array[@]:0:$max} ${array[@]:($max+1)} )

                # Start over
                i=-1
                break
            fi
            j=$((j+1))
        done

        i=$((i+1))
    done

    eval "$1=(${array[@]})"
}

# Ask confirmation from user
# $1 - question
# $2 - message printing if not sure
function confirm() {
    check_num_args 1 $# $FUNCNAME
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

# Requires config file
# Uses: OPTIONS, MODULES
function require_conf() {
    for opt in "${!OPTIONS[@]}"; do
        if [[ $opt = 'conf' ]]; then
            CONF="${OPTIONS[$opt]}"
            check_file $CONF
            . "$CONF"
            break
        fi
    done
    if [[ ${#MODULES[@]} > 1 && -z $CONF ]]; then
        echo "If you specify more than one module, config is required."
        exit 1
    fi
}

# Объявления массивов опций для модулей
# Uses: MODULES
function declare_options_arrays() {
    for module in "${MODULES[@]}"; do
        get_module_opts_var $module
        declare -Ag "$MODULE_OPTS_VAR"
    done
}

# Copies elements from OPTIONS to ${MODULE}_OPTS
# Uses: OPTIONS, MODULES
function assign_module_opts() {
    get_module_opts_var ${MODULES[0]}
    for opt in "${!OPTIONS[@]}"; do
        if [[ $opt = 'conf' ]]; then
            continue
        fi
        eval "$MODULE_OPTS_VAR[$opt]="${OPTIONS[$opt]}""
    done
}

# Prints list of added modules
# Uses: ADDED_MODULES
function echo_added_modules() {
    if [[ ${#ADDED_MODULES[@]} -eq 0 ]]; then
        return 0
    fi
    echo "Dependencies:"
    local module
    for module in "${ADDED_MODULES[@]}"; do
        echo " - $module"
    done
}

# Имя массива, хранящего опции модуля
# $1 - module
function get_module_opts_var() {
    check_num_args 1 $# $FUNCNAME
    local module=$1
    local upcase_module="$(echo $module | tr '[a-z]' '[A-Z]')"
    MODULE_OPTS_VAR="${upcase_module}_OPTS"
}

# Uses: OPTIONS
function check_redundant_options() {
    if [[ ${#OPTIONS[@]} -gt 1 ]]; then
        echo "Warning: If you specify a config file, options in the console are ignored."
    fi
}

# $1 - module
# Uses: MODULES
function remove_from_list() {
    check_num_args 1 $# $FUNCNAME
    local module=$1
    for i in "${!MODULES[@]}"; do
        if [[ ${MODULES[$i]} = $module ]]; then
            unset MODULES[$i]
            break
        fi
    done
}

# Uses: INSTALLED
function echo_installed() {
    if [[ $INSTALLED = true ]]; then
        echo "The 'user' module is installed"
    else
        echo "The 'user' module is not installed"
    fi
}