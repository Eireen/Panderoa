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
    read -n 1 -p "$1 (y/[a])"
    [[ $REPLY =~ ^[Yy]$ ]] || {
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
        echo "To work with several modules, you must specify the configuration file."
        exit 1
    fi
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
    echo "Added dependencies:"
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
    local var_name='OPTS'
    local upcase_module="$(echo $module | tr '[a-z]' '[A-Z]')"
    MODULE_OPTS_VAR="${upcase_module}_${var_name}"
}

# Uses: OPTIONS
function check_redundant_options() {
    if [[ ${#OPTIONS[@]} -gt 1 ]]; then
        echo "Warning: If you specified a config file, options in the console are ignored."
    fi
}

# Removes module from module list
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

# Uses: MODULES_STATUS
function echo_modules_status() {
    for module in "${!MODULES_STATUS[@]}"; do
        if [[ ${MODULES_STATUS[$module]} = true ]]; then
            echo "Module '$module' is installed"
        else
            echo "Module '$module' is not installed"
        fi
    done
}

function check_pack_status_by_apt() {
    check_num_args 1 $# $FUNCNAME
    local pack=$1
    PACK_INSTALLED=true
    local result=`aptitude search "^$pack$"`
        if [[ $? -ne 0 ]]; then
            PACK_INSTALLED=false
            return
        fi
        local state=${result:0:1}
        if [[ $state = 'c' || $state = 'p' ]]; then
            PACK_INSTALLED=false
            return
        fi
}

function check_pack_status_by_dpkg() {
    check_num_args 1 $# $FUNCNAME
    local pack=$1
    PACK_INSTALLED=true
    dpkg -s $pack >& /dev/null || {
        PACK_INSTALLED=false
        return
    }
    local info=`dpkg -s $pack`
    local pos=`awk -v a="$info" -v b="not-installed" 'BEGIN{print index(a,b)}'`
    if [[ $pos -ne 0 ]]; then
        PACK_INSTALLED=false
    fi
}