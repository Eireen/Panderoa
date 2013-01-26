#!/bin/bash

function require_module_file() {
    # $1 - module
    # $1 - file

    local path=$MODULES_PATH/$1/$2.sh
    local filetype

    case "$path" in

        "$MODULES_PATH/$1/$DEPS_FILE" )
            filetype="dependencies"
        ;;

        "$MODULES_PATH/$1/$PACKS_FILE" )
            filetype="packages"
        ;;

        "$MODULES_PATH/$1/$OPTS_FILE" )
            filetype="options"
        ;;

    esac

    if [ -z $filetype ]; then
        echo "Warning: type file "$path" required is not standard!"
    fi

    check_file $path "Error: ${filetype-"$2"} for module \"$1\" does not specified!"

    if [ $? -eq 0 ]; then
        . ./$path
    fi
}

function execute_module_command() {
    # $1 - module
    # $2 - command

    local path=$MODULES_PATH/$1/$2.sh
    local is_standard=1

    for command in "${COMMANDS[@]}"; do
        if [[ $command == $2 ]]; then
            is_standard=0
        fi
    done

    if [ is_standard -ne 0 ]; then
        echo "Warning: command \"$2\" is not standard!"
    fi

    check_file $path "Error: command \"$2\" for module \"$1\" does not specified!"

    if [ $? -eq 0 ]; then
        . ./$path
    fi
}

function require_module_deps() {
    # $1 - module

    require_module_file $1 $DEPS_FILE
}

function require_module_packs() {
    # $1 - module

    require_module_file $1 $PACKS_FILE
}

function require_module_opts() {
    # $1 - module

    require_module_file $1 $OPTS_FILE
}

# -------------- Shortcuts -------------- #

function install_module() {
    # $1 - module

    execute_module_command $1 "install"
}

function remove_module() {
    # $1 - module

    execute_module_command $1 "remove"
}

function purge_module() {
    # $1 - module

    execute_module_command $1 "purge"
}

function update_module() {
    # $1 - module

    execute_module_command $1 "update"
}

function upgrade_module() {
    # $1 - module

    execute_module_command $1 "upgrade"
}

function check_module() {
    # $1 - module

    execute_module_command $1 "check"
}