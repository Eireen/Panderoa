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
function check_project_completeness() {
    # TODO
    :
}

# Extend the list of modules on the basis of their dependencies, by adding new modules
# Uses: MODULES
function extend_modules_by_deps() {
    local i=0
    local j=0

    ADDED_MODULES=()
    local original_modules=(${MODULES[@]})

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

                    [[ ${original_modules[@]} =~ $dep_module ]] || {
                        ADDED_MODULES[${#ADDED_MODULES[@]}]="$dep_module"
                    }

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
# Uses: MODULES_PATH, DEPS_FILE, PACKS_FILE, OPTS_FILE, STANDARD_COMMANDS, SHELL_EXTENSION
function check_module_completeness() {
    check_num_args 1 $# $FUNCNAME
    local module=$1

    local module_dir="$MODULES_PATH/$module"
    check_dir $module_dir

    check_file "$module_dir/$DEPS_FILE"
    check_file "$module_dir/$PACKS_FILE"
    check_file "$module_dir/$OPTS_FILE"

    for command in "${STANDARD_COMMANDS[@]}"; do
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
        echo "Modules are not specified!"
        exit 1
    fi
}

# Определение команды, выполняемой над модулями
function get_command() {
    for arg; do
        [[ ${STANDARD_COMMANDS[@]} =~ $arg ]] && {
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
# $1 - module
function get_unused_packs() {
    check_num_args 1 $# $FUNCNAME

    require_packs "$1"

    declare -a res_packs=("${PACKS[@]}")

    for module in "${STANDARD_MODULES[@]}"; do
        if [[ $1 != $module ]]; then

            [[ ${MODULES[@]} =~ $module ]] && {
                continue
            }

            check_module "$module"
            if [[ $INSTALLED = false ]]; then
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

# Проверка уже установленных (при вызове install) или отсутствующих (при вызове check или purge) модулей и удаление их из списка
function check_modules_status() {
    for module in "${MODULES[@]}"; do
        check_module $module
        if [[ $COMMAND = 'install' ]]; then
            if [[ $INSTALLED = true ]]; then
                echo "Module '$module' is already installed"
                remove_from_list $module
            elif [[ $INSTALLED_BY_DEFAULT = true ]]; then
                confirm "Module '$module' is already installed, but with different settings. Do I try to change them?" "Installation cancelled by user."
                MODIFY[${#MODIFY[@]}]=$module
            else
                NEW[${#NEW[@]}]=$module
            fi
        else
            if [[ $INSTALLED_BY_DEFAULT = false ]]; then
                echo "Module '$module' is not installed"
                remove_from_list $module
            fi
        fi
    done
}

# Проверка, существуют ли установленные модули, зависящие от удаляемых
# Uses: MODULES, STANDARD_MODULES
function check_dependents() {
    for module in "${MODULES[@]}"; do
        local dependents=()
        for st_module in "${STANDARD_MODULES[@]}"; do
            if [[ $st_module = $module ]]; then
                continue
            fi
            [[ ${MODULES[@]} =~ $st_module ]] && {
                continue
            }

            require_deps $st_module
            [[ ${DEPS[@]} =~ $module ]] && {
                check_module $st_module
                if [[ $INSTALLED != true ]]; then
                    continue
                fi
                dependents[${#dependents[@]}]=$st_module
            }
        done

        if [[ ${#dependents[@]} -gt 0 ]]; then
            echo "The following modules depend on the module '$module':"
            for m in "${dependents[@]}"; do
                echo " - $m"
            done
        fi
    done
}

function get_ip() {
    IP=`ip -4 a l dev eth1  | grep inet | awk '{ print $2 }'`
    local pos=`expr index $IP /`
    [[ $pos -ne 0 ]] && {
        IP=${IP:0:(($pos-1))}
    }
}