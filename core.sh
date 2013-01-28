#!/bin/bash

MODULES_DIR="/home/eireen/Panderoa/modules"

. ./commands.sh
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
    
    echo_added_modules
}

# 6. Проверка целостности модуля
# Arguments: 
# 1 - module
# Uses:
#  - MODULES_DIR
function check_module_integrity() {
    # TODO
    check_num_args 1 $# $FUNCNAME
    local module=$1

    MODULE_DIR="$MODULES_DIR/$module"
    checkDir $MODULE_DIR

    DEPS_FILE="$MODULE_DIR/$module/deps.sh"
    checkFile $DEPS_FILE
    # TODO: check if variables DEPS, PACKS, OPTS defined

    PACKS_FILE="$MODULE_DIR/$module/packs.sh"
    checkFile $PACKS_FILE

    OPTS_FILE="$MODULE_DIR/$module/opts.sh"
    checkFile $OPTS_FILE    
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

# Составление списка всех возможных опций
# Returns:
#  - ALL_SHORT_OPTS
#  - ALL_LONG_OPTS
function collect_options_from_files() {
    FILES=`find $MODULES_DIR -wholename "*/opts.sh"`

    OLD_IFS=$IFS
    IFS=`echo -en "\n\b"`

    for file in $FILES; do
        . "$file"
        ALL_SHORT_OPTS="${ALL_SHORT_OPTS}${SHORT_OPTS}"
        ALL_LONG_OPTS="${ALL_LONG_OPTS},${LONG_OPTS}"
    done

    IFS=$OLD_IFS

    ALL_LONG_OPTS=${ALL_LONG_OPTS:1}
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

# (3, 4, 8). Разбор входных данных (команда, опции и модули)
# Returns:
#  - COMMAND
#  - OPTIONS
#  - MODULES
function parse_input() {
    collect_options_from_files
    ALL_LONG_OPTS="${ALL_LONG_OPTS},conf:"

    PARSED=`getopt -o $ALL_SHORT_OPTS -l ${ALL_LONG_OPTS} -- "$@"`
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
            opt="${opt:1}"  # остаётся ли opt здесь локальной??
            check_option_arg $opt "$ALL_SHORT_OPTS"
        else
            # Длинная опция
            opt="${opt:2}"
            check_option_arg $opt "$ALL_LONG_OPTS"
        fi
        if [[ true = "$WITH_ARG" ]]; then
            OPTIONS["$opt"]="$2"
            shift 2
        else
            OPTIONS["$opt"]=""
            shift
        fi
    done

    for operand; do
        [[ ${COMMANDS[*]} =~ $operand ]] && {
            if [[ -z "$COMMAND" ]]; then
                COMMAND="$operand"
                continue
            fi
        }
        MODULES[${#MODULES[@]}]=$operand
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
# $2: options like 'l', 'login', 'l/login'
function check_required_options() {

    function check_opt() {
        check_num_args 1 $# $FUNCNAME
        local req_opt=$1
        for opt in "${OPTIONS[@]}"; do
            if [[ $opt = $req_opt ]]; then
                return 0
            fi
        done
        return 1
    }

    check_num_args 2 $# $FUNCNAME
    local error_message="Required option ${opt_forms[0]} not found"
    local delimiter='='
    local module=$1
    shift
    for req_opt; do
        if [[ `expr index $req_opt $delimiter` -ne 0 ]]; then
            local opt_forms=(${req_opt//;/ })
            local found=false
            for opt_form in "${opt_forms[@]}"; do
                if [[ `check_opt $opt_form` -eq 0 ]]; then
                    found=true
                fi
            done
            if [[ $found = false ]]; then
                echo error_message
                exit 1
            fi
        else
            [[check_opt $req_opt ]] || {
                echo error_message
                exit 1
            }
        fi
        shift
    done
}