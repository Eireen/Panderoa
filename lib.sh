#!/bin/bash

# Determines whether the number of arguments a function requires
# $1: required number of arguments
# $2: actual number of arguments
# $3: function name
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
# $1: the path to test
# $2: the error message
# exit code: 0 if path refers to an existing directory; otherwise, 1
function check_dir() {
    check_num_args 1 $# $FUNCNAME

    if [[ ! -d "$1" ]]; then
        echo "${2-Error: directory \"`pwd`/$1\" does not exist!}"
        exit 1
    fi
}

# Determines whether the specified path refers to an existing file
# $1: the path to test
# $2: the error message
# exit code: 0 if path refers to an existing file; otherwise, 1
function check_file() {
    check_num_args 1 $# $FUNCNAME

    if [[ ! -f "$1" ]]; then
        echo "${2-Error: file \"`pwd`/$1\" does not exist!}"
        exit 1
    fi
}

# Determines whether the specified object exists as an element in an Array object
# $1: the array to search
# $2: the object to find in the array
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

    # При задании нескольких модулей конфиг обязателен
    if [[ ${#MODULES[@]} > 1 && -z $CONF ]]; then
        echo "To install more than one module, use the config file."
        exit 1
    fi
}

# Проверка количества заданных модулей
# Uses: MODULES
function check_modules_count() {
    if [[ ${#MODULES[@]} -eq 0 ]]; then
        echo "Modules are not defined"
        exit 1
    fi
}

# Объявления массивов опций для модулей
# Uses: MODULES
function declare_options_arrays() {
    for module in "${MODULES[@]}"; do
        local upcase_module="$(echo $module | tr '[a-z]' '[A-Z]')"
        VAR="${upcase_module}_OPTS"
        declare -Ag "$VAR"
    done
}

# Copies elements from OPTIONS to ${MODULE}_OPTS
# Uses: OPTIONS, MODULES
function assign_options_array() {
    local module="$(echo ${MODULES[0]} | tr '[a-z]' '[A-Z]')"
    VAR="${module}_OPTS"

    for opt in "${!OPTIONS[@]}"; do
        if [[ $opt = 'conf' ]]; then
            continue
        fi
        eval "$VAR[$opt]="${OPTIONS[$opt]}""
    done
    eval "declare -p $VAR"
}

#Uses: ADDED_MODULES
function echo_added_modules() {
    echo "Added modules: "
    local module
    for module in "${ADDED_MODULES[@]}"; do
        echo " - $module"
    done
}

# Проверить, какие из добавленных модулей уже установлены и удалить их из списков
function check_already_installed() {
    declare -A CHECKS
    # - проверка с "пустыми" опциями
    for module in "${ADDED_MODULES}"; do
        local options_array_var="${module}_OPTS"
        check_module $module
        CHECKS["$module"]=$INSTALLED
    done
    # - проверка с реальными опциями
}

# function get_module_opts_array_var