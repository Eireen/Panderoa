#!/bin/bash

. ./core.sh

function save_options() {
    declare -Ag OPTIONS_BUFFER
    for opt in "${!OPTIONS[@]}"; do
        OPTIONS_BUFFER["$opt"]="${OPTIONS[$opt]}"
    done
}

function restore_option() {
    for opt in "${!OPTIONS_BUFFER[@]}"; do
        OPTIONS["$opt"]="${OPTIONS_BUFFER[$opt]}"
    done
}

# sudo ./main.sh user -l someuser -p testpass --conf conf.sh

# Проверка прав на выполнение
check_uid

# Проверка целостности проекта
check_project_integrity

# Разбор входных данных
parse_input $*

# Проверка наличия списка модулей
check_modules_count

# Очистка списка модулей от повторяющихся элементов
clear_from_repetitives MODULES

# Расширение списка модулей зависимостями из deps-файлов
extend_modules_by_deps

# Объявления массивов опций для модулей
declare_options_arrays

# Подключение файла конфигурации, если задан
require_conf

# Опции, заданные параллельно с конфигом, игнорируются
if [[ ${#MODULES[@]} -eq 1 ]]; then
    if [[ -z $CONF ]]; then
        assign_options_array
    else
        if [[ ${#OPTIONS[@]} -gt 0 ]]; then
            echo "Warning: If you specify a config file, options in the console are ignored. Use the config file."
            # TODO: confirm??
        fi
    fi
fi

# Проверить, какие из добавленных модулей уже установлены и удалить их из списков
check_already_installed



#declare -p OPTIONS
#declare -p MODULES
#declare -p ADDED_MODULES