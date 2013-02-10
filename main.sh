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
    if [[ ${#ADDED_MODULES[@]} -gt 0 ]]; then
        confirm "Are you sure you want to continue?" "Installation was cancelled by user."
    fi
fi  

# Объявления массивов опций для модулей
for module in "${MODULES[@]}"; do
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

# Проверить, какие из добавленных модулей уже установлены и удалить их из списков
if [[ $COMMAND = 'install' || $COMMAND = 'remove' || $COMMAND = 'purge' ]]; then
    check_already_installed
    if [[ ${#MODULES[@]} -eq 0 ]]; then
        exit
    fi
    if [[ $COMMAND = 'install' ]]; then
        echo "Будут установлены следующие модули:"
    else
        echo "Будут удалены следующие модули:"
    fi
    for m in "${MODULES[@]}"; do
        echo " - $m"
    done
    confirm "Are you sure you want to continue?"
fi

# Собственно выполнение команды над модулями
for module in "${MODULES[@]}"; do
    execute_module_command $module $COMMAND
done

if [[ $COMMAND = 'check' || $COMMAND = 'cheek' ]]; then
    echo_installed
fi