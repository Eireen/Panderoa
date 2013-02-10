#!/bin/bash

MODULES_DIR="/home/eireen/Panderoa/modules"
declare -A OPTIONS

. ./environment.sh
. ./commands.sh
. ./modules.sh

. ./lib.sh
. ./module.sh

# Проверка прав на выполнение
function check_uid() {
    if [[ $UID -ne 0 ]]; then
        echo "Error: You must be root to run this script!"
        exit 1
    fi
}

# Проверка целостности проекта
function check_project_integrity() {
    # TODO
    :
}

# Extend the list of modules on the basis of their dependencies, by adding new modules
# Uses: MODULES
function extend_modules_by_deps() {
    local i=0
    local j=0

    ADDED_MODULES=()

    while [ $i -lt ${#MODULES[@]} ]; do 
        local path="$MODULES_PATH/${MODULES[$i]}/$DEPS_FILE"

        if [ -f $path ]; then
            . $path

            for dep_module in "${DEPS[@]}"; do
                if [[ $dep_module == ${MODULES[$i]} ]]; then
                    echo "Warning: invalid dependency, module \"$dep_module\" is pointed at itself!"
                    continue
                fi

                # Remove the dependent module after the current one
                local j=$i
                while [ $j -le ${#MODULES[@]} ]; do
                    if [[ $dep_module == ${MODULES[$j]} ]]; then
                        MODULES=( ${MODULES[@]:0:$j} ${MODULES[@]:($j+1)} )
                    fi
                    j=$(($j+1))
                done

                # Check if the dependent module is found before the current one
                local is_found_before=0
                local j=0
                while [ $j -le $i ]; do
                    if [[ "$dep_module" = "${MODULES[$j]}" ]]; then
                        is_found_before=1
                        break
                    fi
                    j=$(($j+1))
                done

                if [ $is_found_before -ne 1 ]; then
                    # Insert the dependent module before the current one
                    MODULES=( ${MODULES[@]:0:$i} "$dep_module" ${MODULES[@]:$i} )

                    ADDED_MODULES[${#ADDED_MODULES[@]}]="$dep_module"

                    # Start over
                    i=-1
                    break
                fi
            done
        fi

        i=$(($i+1))
    done
}

# Проверка целостности модуля
# $1 - module
# Uses: MODULES_PATH, DEPS_FILE, PACKS_FILE, OPTS_FILE, COMMANDS, SHELL_EXTENSION
function check_module_integrity() {
    check_num_args 1 $# $FUNCNAME
    local module=$1

    local module_dir="$MODULES_PATH/$module"
    check_dir $module_dir

    check_file "$module_dir/$DEPS_FILE"
    check_file "$module_dir/$PACKS_FILE"
    check_file "$module_dir/$OPTS_FILE"

    for command in "${COMMANDS[@]}"; do
        local command_file="$module_dir/$command.$SHELL_EXTENSION"
        check_file $command_file
    done
}

# Определение заданных модулей
function get_modules() {
    for arg; do
        local is_standard=false
        for st_module in "${STANDARD_MODULES[@]}"; do
            if [[ $arg = $st_module ]]; then
                is_standard=true
                break
            fi
        done
        if [[ $is_standard = true ]]; then
            MODULES[${#MODULES[@]}]=$arg
        fi
    done

    if [[ ${#MODULES[@]} -eq 0 ]]; then
        echo "Modules are not specified"
        exit 1
    fi
}

# Определение команды, выполняемой над модулями
function get_command() {
    for arg; do
        [[ ${COMMANDS[@]} =~ $arg ]] && {
            if [[ -z "$COMMAND" ]]; then
                COMMAND="$arg"
                break
            fi
        }
    done

    if [[ -z $COMMAND ]]; then
        echo "Command is not specified!"
        exit 1
    fi
}

# Проверка наличия аргумента у опции
# $1 - option
# $2 - option list (short or long)
function check_option_arg() {
    check_num_args 2 $# $FUNCNAME
    WITH_ARG=false
    local opt="$1"
    local optlist="$2"
    local pos=`awk -v a="$optlist" -v b="$opt" 'BEGIN{print index(a,b)}'`
    # Ищем опцию в соответствующем списке...
    local next=$(($pos+${#opt}))
    if [[ $next -le ${#optlist} ]]; then
        # ...и проверяем, идёт ли следом двоеточие
        if [[ : = ${optlist:$(($next-1)):1} ]]; then
            WITH_ARG=true
        fi
    fi
}

# Разбор входных данных (команда, опции и модули)
function parse_options() {
    local module="${MODULES[0]}"
    require_opts $module

    local cmd_str="getopt"
    if [[ ! -z $SHORT_OPTS ]]; then
        cmd_str="$cmd_str -o $SHORT_OPTS"
    fi

    if [[ ! -z $LONG_OPTS ]]; then
        LONG_OPTS="$LONG_OPTS,"
    fi
    LONG_OPTS="${LONG_OPTS}conf:"

    cmd_str="$cmd_str -l $LONG_OPTS"

    local parsed=`$cmd_str -- "$@"`
    if [[ $? -ne 0 ]]; then
        # TODO: echo "getopt error" >&2
        exit 1
    fi

    eval set -- "$parsed"

    while true; do
        if [[ -- = "$1" ]]; then
            shift
            break
        fi
        local opt="$1"
        # Должен ли быть аргумент у опции
        if [[ ${#opt} -eq 2 ]]; then
            # Короткая опция
            opt="${opt:1}"
            check_option_arg $opt "$SHORT_OPTS"
        else
            # Длинная опция
            opt="${opt:2}"
            check_option_arg $opt "$LONG_OPTS"
        fi
        if [[ true = "$WITH_ARG" ]]; then
            OPTIONS["$opt"]="$2"
            shift 2
        else
            OPTIONS["$opt"]=""
            shift
        fi
    done

    for other; do
        if [[ $other = $COMMAND ]]; then
            continue
        fi
        local is_module=false
        for module in "${MODULES[@]}"; do
            if [[ $other = $module ]]; then
                is_module=true
                break
            fi
        done
        if [[ $is_module = false ]]; then
            echo "Unknown argument: $other"
        fi
    done

    
}

# Prepare a list of packages to remove for the specified module
# Удаление пакетов, используемых другими модулями
# $1: module
function packs_to_remove() {
    check_num_args 1 $# $FUNCNAME

    require_packs "$1"

    declare -a res_packs=("${PACKS[@]}")

    for module in "${STANDARD_MODULES[@]}"; do
        if [[ $1 != $module ]]; then
            [[ ${MODULES[@]} =~ $module ]] && {
                continue
            }
            cheek_module "$module"
            get_module_installed_var $module
            eval "local installed=\$$MODULE_VAR"
            if [[ $installed = false ]]; then
                continue
            fi

            require_packs "$module"

            local i=0
            while [[ $i -lt ${#PACKS[@]} ]]; do

                local j=0
                while [[ $j -lt ${#res_packs[@]} ]]; do
                    if [[ ${res_packs[$j]} == ${PACKS[$i]} ]]; then
                        res_packs=( ${res_packs[@]:0:$j} ${res_packs[@]:($j+1)} )
                    fi

                    j=$((j+1))
                done

                i=$((i+1))
            done
        fi
    done

    PACKS=(${res_packs[@]})
}

# Проверка наличия требуемых опций
# Uses: OPTIONS
# $1: module
# $2: options like 'l', 'login', 'l=login'
function check_required_options() {

    function check_opt() {
        check_num_args 1 $# $FUNCNAME
        local req_opt=$1
        for opt in "${module_opts[@]}"; do
            if [[ $opt = $req_opt ]]; then
                return 0
            fi
        done
        return 1
    }

    function print_err() {
        check_num_args 1 $# $FUNCNAME
        local opt=$1
        echo "Required option '$opt' not found"
    }

    check_num_args 2 $# $FUNCNAME
    local delimiter='='
    local module=$1
    get_module_opts_var $module
    eval local module_opts=("\${!$MODULE_VAR[@]}")
    shift
    for req_opt; do
        if [[ `expr index $req_opt $delimiter` -ne 0 ]]; then
            local opt_forms=(${req_opt//$delimiter/ })
            local found=false
            for opt_form in "${opt_forms[@]}"; do
                check_opt $opt_form
                if [[ $? -eq 0 ]]; then
                    found=true
                fi
            done
            if [[ $found = false ]]; then
                print_err $req_opt
                exit 1
            fi
        else
            check_opt $req_opt
            if [[ $? -ne 0 ]]; then
                print_err $req_opt
                exit 1
            fi
        fi
    done
}

# Проверить, какие из добавленных модулей уже установлены и удалить их из списка
function check_already_installed() {
    declare -A checks
    for module in "${MODULES[@]}"; do
        get_module_installed_var $module
        eval "$MODULE_VAR=false"
        cheek_module $module
        eval "local installed=\$$MODULE_VAR"
        if [[ ($COMMAND = 'remove' || $COMMAND = 'purge') && $installed = false ]]; then
            echo "Module $module is not installed"
            remove_from_list $module
            continue
        else
            eval "checks[$module]=\$$MODULE_VAR"
        fi
    done
    if [[ $COMMAND != 'install' ]]; then
        return
    fi
    for module in "${MODULES[@]}"; do
        get_module_installed_var $module
        eval "$MODULE_VAR=false"
        check_module $module
        eval "installed=\$$MODULE_VAR"
        if [[ $installed = true && ${checks[$module]} = true ]]; then
            echo "Module $module is already installed"
            remove_from_list $module
        fi
        if [[ $installed = false && ${checks[$module]} = true ]]; then
            echo "Module $module is already installed, but with different parameters"
            exit 1
        fi
    done
}

