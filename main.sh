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

# Расширение списка модулей зависимостями из deps-файлов
extend_modules_by_deps

echo_added_modules

# Объявления массивов опций для модулей
declare_options_arrays

# Подключить конфиг (если задан)
require_conf

# Опции, заданные параллельно с конфигом, игнорируются
if [[ ! -z $CONF ]]; then
    check_redundant_options
fi

# Проверить, какие из добавленных модулей уже установлены и удалить их из списков
if [[ $COMMAND = 'install' ]]; then
    check_already_installed
fi

# Собственно выполнение команды над модулями
for module in "${MODULES[@]}"; do
    execute_module_command $module $COMMAND
done