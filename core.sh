#!/bin/bash

MODULES_DIR="/home/eireen/Panderoa/modules"

. ./lib.sh

COMMANDS=(
    "install"
    "remove"
    "purge"
    "update"
    "upgrade"
    "check"
)

# 1. Проверка прав на выполнение
function checkUID() {
    if [[ `id -u` -ne 0 ]]; then
        echo "Error: You must be root to run this script!"
        exit 1
    fi
}

# 2. Проверка целостности проекта
function checkProjectIntegrity() {
    # TODO
    :
}

# 5. Расширение списка модулей зависимостями из deps-файлов
function extendModulesByDeps() {
    # TODO
    :
}

# 6. Проверка целостности модуля
function checkModuleIntegrity() {
    # TODO
    checkNumArgs 1 $# "Error: function checkModuleIntegrity() requires at least 1 argument"
    local module=$1
    MODULE_DIR="$MODULES_DIR/$module"
    checkDir $MODULE_DIR
    # обязательны ли deps.sh и packs.sh?
    DEPS_FILE="$MODULE_DIR/$module/deps.sh"
    checkFile $DEPS_FILE
    PACKS_FILE="$MODULE_DIR/$module/packs.sh"
    checkFile $PACKS_FILE
}

# Проверка наличия установленных пакетов
# Arguments:
# 1 - module
# Uses:
#  - MODULES_DIR
# Returns:
#  - INSTALLED
function checkInstalledPacks() {
    checkNumArgs 1 $# "Error: function checkInstalledPacks() requires at least 1 argument"
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
function checkInstalledModule() {
    checkNumArgs 1 $# "Error: function checkInstalledModule() requires at least 1 argument"
    local module=$1
    INSTALLED=true
    checkInstalledPacks $module
    if [[ INSTALLED ]]; then
        CHECK_FILE="$MODULES_DIR/$module/check.sh"
        if [[ -f $CHECK_FILE ]]; then
            . $CHECK_FILE
        fi
    fi
}

# Составление списка всех возможных опций
# Returns:
#  - SHORT_OPTS
#  - LONG_OPTS
function collectOptionsfromFiles() {
    FILES=`find $MODULES_DIR -wholename "*/opts.sh"`

    OLD_IFS=$IFS
    IFS=`echo -en "\n\b"`

    for file in $FILES; do
        . "$file"
        for opt in "${!OPTS[@]}"; do
            SHORT_OPTS="$SHORT_OPTS$opt"
            LONG_OPTS="$LONG_OPTS,${OPTS[$opt]}"
        done
    done

    IFS=$OLD_IFS

    LONG_OPTS=${LONG_OPTS:1}
}

# Проверка наличия аргумента у опции
# Arguments:
# 1 - option
# 2 - option list (short or long)
# Returns:
#  - WITH_ARG - флаг наличия аргумента у опции
function checkOptionArg() {
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
# TODO: разбор опций нескольких модулей (??)
# Returns:
#  - COMMAND
#  - OPTIONS
#  - MODULES
function parseInput() {
    collectOptionsfromFiles

    PARSED=`getopt -o $SHORT_OPTS -l ${LONG_OPTS},conf: -- "$@"`
    if [[ $? -ne 0 ]]; then
        echo "getopt error" >&2
        exit 1
    fi

    eval set -- "$PARSED"
    declare -A OPTIONS

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
            checkOptionArg $opt "$SHORT_OPTS"
        else
            # Длинная опция
            opt="${opt:2}"
            checkOptionArg $opt "$LONG_OPTS"
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
function loadFile() {
    checkNumArgs 1 $# "Error: function loadFile() requires at least 1 argument"
    local file="$1"
    checkFile "$file"
    . "$file"
}

# Массив списков пакетов для всех модулей
# Uses:
#  - MODULES_DIR
# Returns:
#  - ALL_PACKS: [module]="pack1 pack2 ..."
function getPacksList() {
    declare -Ag ALL_PACKS
    OLD_IFS=$IFS
    IFS=`echo -en "\n\b"`
    for module in `ls "$MODULES_DIR"`; do
        loadFile "$MODULES_DIR/$module/packs.sh"
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
function checkUsages() {
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
function execCommand() {
    getPacksList

    if [[ remove = "$COMMAND" || purge = "$COMMAND" ]]; then
        checkUsages
        if [[ ${#USAGES[@]} -gt 0 ]]; then
            # Показать список используемых пакетов
            echo "These packages associated with removing modules are now being used in other modules and cannot be removed:"
            for pack in "${!USAGES[@]}"; do
                echo " - $pack in ${USAGES[$pack]}"
            done
        fi
        confirm "Remove given modules? (y/[a]): "
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