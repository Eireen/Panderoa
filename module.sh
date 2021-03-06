#!/bin/bash

# $1 - module
# $2 - file
function require_module_file() {
    check_num_args 2 $# $FUNCNAME

    local path="$MODULES_PATH/$1/$2"

    check_file $path "Error: ${filetype-"$2"} for module \"$1\" does not specified!"
    . ./$path

    case "$2" in
        "$DEPS_FILE" )
            local filetype="dependencies"
            ;;
        "$PACKS_FILE" )
            local filetype="packages"
            ;;
        "$OPTS_FILE" )
            local filetype="options"
            ;;
        esac

    if [[ -z $filetype ]]; then
        echo "Warning: type file "$path" required is not standard!"
        return 2
    fi
}

# $1 - module
function require_deps() {
    check_num_args 1 $# $FUNCNAME

    require_module_file $1 $DEPS_FILE

    if [[ 0 -ne $? ]]; then
        return 2
    fi
}

# $1 - module
function require_packs() {
    check_num_args 1 $# $FUNCNAME

    require_module_file $1 $PACKS_FILE

    if [[ 0 -ne $? ]]; then
        return 2
    fi
}

# $1 - module
function require_opts() {
    check_num_args 1 $# $FUNCNAME

    require_module_file $1 $OPTS_FILE

    if [[ 0 -ne $? ]]; then
        return 2
    fi
}


# $1 - command
function perform_at_packs {
    check_num_args 1 $# $FUNCNAME

    for pack in "${PACKS[@]}"; do
        apt-get $1 $pack -y || {
            echo "Error: failed to $1 at the package \"$pack\"!"
            exit 1
        }
    done
}

# $1 - module
function install_packs() {
    check_num_args 1 $# $FUNCNAME
    local module=$1

    require_packs $module
    perform_at_packs "install"
}

# $1 - module
function purge_packs() {
    check_num_args 1 $# $FUNCNAME
    local module=$1

    require_packs $module
    get_unused_packs $module
    perform_at_packs "purge"
    apt-get autoclean -y
    apt-get autoremove -y
}

# $1 - module
function check_packs() {
    check_num_args 1 $# $FUNCNAME
    local module=$1

    require_packs $module
    PACKS_INSTALLED=true

    for pack in "${PACKS[@]}"; do
        check_pack_status_by_apt $pack
        if [[ $PACK_INSTALLED = false ]]; then
            PACKS_INSTALLED=false
            return
        fi
    done
}


# $1 - module
function install_module() {
    check_num_args 1 $# $FUNCNAME

    execute_module_command $1 "install"

    if [[ 0 -ne $? ]]; then
        return 2
    fi
}

# $1 - module
function purge_module() {
    check_num_args 1 $# $FUNCNAME

    execute_module_command $1 "purge"

    if [[ 0 -ne $? ]]; then
        return 2
    fi
}

# $1 - module
function check_module() {
    check_num_args 1 $# $FUNCNAME

    execute_module_command $1 "check"

    if [[ 0 -ne $? ]]; then
        return 2
    fi
}


# $1 - module
# $2 - command
function execute_module_command() {
    check_num_args 2 $# $FUNCNAME

    local path="$MODULES_PATH/$1/$2.$SHELL_EXTENSION"

    check_file $path "Error: the command \"$2\" for module \"$1\" does not specified!"
    . ./$path

    [[ ${STANDARD_COMMANDS[@]} =~ $2 ]] || {
        echo "Warning: the command \"$2\" is not standard!"
        return 2
    }
}
