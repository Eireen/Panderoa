#!/bin/bash

. ./core.sh

# sudo ./main.sh user -l someuser -p testpass --conf conf.sh

# Проверка прав на выполнение
check_uid

# Проверка целостности проекта
check_project_integrity

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

# Проверка целостности модулей
for module in "${MODULES[@]}"; do
    check_module_integrity $module
done

# Объявления массивов опций для модулей
declare_options_arrays

# Подключить конфиг (если задан)
require_conf

# Опции, заданные параллельно с конфигом, игнорируются
if [[ ${#MODULES[@]} -eq 1 ]]; then
    if [[ -z $CONF ]]; then
        assign_module_opts
    else
        if [[ ${#OPTIONS[@]} -gt 0 ]]; then
            echo "Warning: If you specify a config file, options in the console are ignored."
            # TODO: confirm??
        fi
    fi
fi

# ----------------------

# Проверить, какие из добавленных модулей уже установлены и удалить их из списков
check_already_installed



#declare -p OPTIONS
#declare -p MODULES
#declare -p ADDED_MODULES