#!/bin/bash

MODULES_DIR="/home/eireen/Panderoa/modules"

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
function extend_modules_by_deps() {
    DEPS_FILE="deps.sh"

    local i=0
    local j=0

    ADDED_MODULES=()

    while [ $i -lt ${#MODULES[@]} ]; do 
        local path="$MODULES_DIR/${MODULES[$i]}/$DEPS_FILE"

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
# Uses: MODULES_DIR
function check_module_integrity() {
    check_num_args 1 $# $FUNCNAME
    local module=$1

    MODULE_DIR="$MODULES_PATH/$module"
    check_dir $MODULE_DIR

    # TODO: check if variables DEPS, PACKS, OPTS are defined
    check_file "$MODULE_DIR/$DEPS_FILE"
    check_file "$MODULE_DIR/$PACKS_FILE"
    check_file "$MODULE_DIR/$OPTS_FILE"

    for command in "${COMMANDS[@]}"; do
        COMMAND_FILE="$MODULE_DIR/$command.$SHELL_EXTENSION"
        check_file $COMMAND_FILE
    done
}

# Проверка наличия установленных пакетов
# Arguments:
# 1 - module
# Uses:
#  - MODULES_DIR
# Returns:
#  - INSTALLED
function check_installed_packs() {
    check_num_args 1 $# $FUNCNAME
    local module=$1
    PACKS_FILE="$MODULES_DIR/$module/packs.sh"
    . $PACKS_FILE
    for pack in "${PACKS[*]}"; do
        dpkg -s $pack > /dev/null 2>&1 || {
            INSTALLED=false
            break
        }
    done
}

# 7. Проверка наличия установленного модуля
# Arguments:
# 1 - module
# Uses:
#  - MODULES_DIR
# Returns:
#  - INSTALLED
function check_installed_module() {
    check_num_args 1 $# $FUNCNAME
    local module=$1
    INSTALLED=true
    check_installed_packs $module
    if [[ INSTALLED ]]; then
        CHECK_FILE="$MODULES_DIR/$module/check.sh"
        if [[ -f $CHECK_FILE ]]; then
            . $CHECK_FILE
        fi
    fi
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
# Arguments:
# 1 - option
# 2 - option list (short or long)
# Returns:
#  - WITH_ARG - флаг наличия аргумента у опции
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
# Uses: MODULES
function parse_options() {
    local module="${MODULES[0]}"
    require_opts $module
    LONG_OPTS="$LONG_OPTS,conf:"

    PARSED=`getopt -o $SHORT_OPTS -l ${LONG_OPTS} -- "$@"`
    if [[ $? -ne 0 ]]; then
        # TODO: echo "getopt error" >&2
        exit 1
    fi

    eval set -- "$PARSED"
    declare -Ag OPTIONS

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

# "Подключение" скрипта
# Arguments:
# 1 - path
function load_file() {
    check_num_args 1 $# $FUNCNAME
    local file="$1"
    checkFile "$file"
    . "$file"
}

# Массив списков пакетов для всех модулей
# Uses:
#  - MODULES_DIR
# Returns:
#  - ALL_PACKS: [module]="pack1 pack2 ..."
function get_all_packs() {
    declare -Ag ALL_PACKS
    OLD_IFS=$IFS
    IFS=`echo -en "\n\b"`
    for module in `ls "$MODULES_DIR"`; do
        load_file "$MODULES_DIR/$module/packs.sh"
        ALL_PACKS["$module"]="${PACKS[@]}"
    done
    IFS=$OLD_IFS
}

# Проверка использования пакетов удаляемых модулей другими модулями
# Uses:
#  - MODULES
#  - ALL_PACKS
# Returns:
#  - USAGES: [pack]="module1/module2/..."
function check_usages() {
    declare -Ag USAGES

    for module in "${MODULES[@]}"; do
        [[ ${!ALL_PACKS[@]} =~ $module ]] || {
            # TODO: Нет файла пакетов - выдавать ли ошибку?
            continue
        }

        PACKS="${ALL_PACKS[$module]}"

        for pack in ${PACKS[@]}; do
            for m in "${!ALL_PACKS[@]}"; do
                [[ ${MODULES[@]} =~ $m ]] && {
                    continue
                }
                for p in ${ALL_PACKS[$m]}; do
                    if [[ "$pack" = "$p" ]]; then
                        USAGES["$pack"]="${USAGES[$pack]}, $m"
                    fi
                done
            done
            # Убрать лишние ', ' в начале
            [[ ${!USAGES[@]} =~ $pack ]] && {
                USAGES["$pack"]=${USAGES["$pack"]:2}
            }
        done

    done
}

# 9. Выполнить apt-get <command> с подстановкой параметров для каждого модуля на основе packs.sh
# Uses:
#  - MODULES_DIR
#  - MODULES
#  - OPTIONS
#  - COMMAND
function exec_command() {
    get_all_packs

    if [[ remove = "$COMMAND" || purge = "$COMMAND" ]]; then
        check_usages
        if [[ ${#USAGES[@]} -gt 0 ]]; then
            # Показать список используемых пакетов
            echo "These packages associated with removing MODULES are now being used in other MODULES and cannot be removed:"
            for pack in "${!USAGES[@]}"; do
                echo " - $pack in ${USAGES[$pack]}"
            done
        fi
        confirm "Remove given MODULES? (y/[a]): "
    fi

    for module in "${MODULES[@]}"; do

        # Выполнение команды над пакетами
        [[ ${!ALL_PACKS[@]} =~ $module ]] || {
            # TODO: Нет файла пакетов - выдавать ли ошибку?
            continue
        }
        PACKS="${ALL_PACKS[$module]}"
        for pack in ${PACKS[*]}; do
            if [[ remove = "$COMMAND" || purge = "$COMMAND" ]]; then
                [[ ${USAGE[@]} =~ $pack ]] && {
                    continue
                }
            fi
            echo "apt-get $COMMAND $pack"
            apt-get $COMMAND $pack || {
                echo "Error when installing the package"
                exit 1
            }
        done

        # Additional scripts
        SCRIPT_FILE="$MODULES_DIR/$module/$COMMAND.sh"
        if [[ -f $SCRIPT_FILE ]]; then
            . $SCRIPT_FILE
        fi

    done
}

# Prepare a list of packages to remove for the specified module
# $1: module
function packs_to_remove() {
    check_num_args 1 $# $FUNCNAME

    require_packs "$1"

    local res_packs="${PACKS[@]}"

    for module in "${MODULES[@]}"; do
        if [[ $1 != $module ]]; then
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

    PACKS="${res_packs[@]}"
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
    local error_message="Required option ${opt_forms[0]} not found"
    local delimiter='='
    local module=$1
    get_module_opts_var $module
    eval local module_opts=("\${!$MODULE_OPTS_VAR[@]}")
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
    declare -A CHECKS
    for module in "${MODULES[@]}"; do
        INSTALLED=false
        cheek_module $module
        CHECKS[$module]=$INSTALLED
    done
    for module in "${MODULES[@]}"; do
        INSTALLED=false
        check_module $module
        if [[ $INSTALLED = true && ${CHECKS[$module]} = true ]]; then
            echo "Module $module is already installed"
            remove_from_list $module
        fi
        if [[ $INSTALLED = false && ${CHECKS[$module]} = true ]]; then
            echo "Module $module is already installed, but with different parameters"
            exit 1
        fi
    done
}

