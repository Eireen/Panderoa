#!/bin/bash

. ./core.sh

# Проверка прав на выполнение
check_uid

# Проверка целостности проекта
check_project_integrity

# Проверка целостности всех модулей
for module in "${STANDARD_MODULES[@]}"; do
    check_module_integrity $module
done

# Команда
get_command $*

# Список модулей
get_modules $*

# Опции
parse_options $*

# Очистка списка модулей от повторяющихся элементов
clear_from_repetitives MODULES

COMMANDS_FOR_ADDING=( 'install' )

# Расширение списка модулей зависимостями из deps-файлов
if [[ ${COMMANDS_FOR_ADDING[@]} =~ $COMMAND ]]; then
    extend_modules_by_deps
    echo_added_modules
fi

# Объявления массивов опций для модулей
for module in "${STANDARD_MODULES[@]}"; do
    get_module_opts_var $module
    declare -A "$MODULE_VAR"
done

# Записать опции в переменную, используемую в скриптах модуля
assign_module_opts

# Подключить конфиг (если задан)
require_conf

# Опции, заданные параллельно с конфигом, игнорируются
if [[ ! -z $CONF ]]; then
    check_redundant_options
fi

if [[ $COMMAND = 'purge' ]]; then
    # Проверка, существуют ли установленные модули, зависящие от удаляемых
    for module in "${MODULES[@]}"; do
        depending_on=()
        for st_module in "${STANDARD_MODULES[@]}"; do
            if [[ $st_module = $module ]]; then
                continue
            fi
            [[ ${MODULES[@]} =~ $st_module ]] && {
                continue
            }

            check_module $st_module
            if [[ $INSTALLED != true ]]; then
                continue
            fi

            require_deps $st_module
            [[ ${DEPS[@]} =~ $module ]] && {
                depending_on[${#depending_on[@]}]=$st_module
            }
        done

        if [[ ${#depending_on[@]} -gt 0 ]]; then
            echo "Модуль $module входит в список зависимостей модулей: "
            for m in "${depending_on[@]}"; do
                echo " - $m"
            done
        fi
    done
fi

# Проверить, какие из добавленных модулей уже установлены и удалить их из списков
if [[ $COMMAND != 'check' ]]; then
    check_already_installed
    if [[ ${#MODULES[@]} -eq 0 ]]; then
        exit
    fi

    function ask_confirm() {
        if [[ $COMMAND = 'install' ]]; then
            echo "Будут установлены модули:"
        elif [[ $COMMAND = 'purge' ]]; then
            echo "Будут удалены модули:"
        fi
        for m in "${MODULES[@]}"; do
            echo " - $m"
        done
        confirm "Are you sure you want to continue?"
    }

    if [[ $COMMAND = 'install' || $COMMAND = 'purge' ]]; then
        ask_confirm
    fi
fi

if [[ $COMMAND = 'check' ]]; then
    declare -A MODULES_INSTALLED
fi

# Собственно выполнение команды над модулями
for module in "${MODULES[@]}"; do
    execute_module_command $module $COMMAND
    if [[ $COMMAND = 'check' ]]; then
        MODULES_INSTALLED[$module]=$INSTALLED
    fi
done

if [[ $COMMAND = 'check' ]]; then
    echo_modules_installed
fi