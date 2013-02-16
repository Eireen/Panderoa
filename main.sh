#!/bin/bash

. ./core.sh

# Проверка прав на выполнение
check_uid

# Проверка целостности проекта
check_project_completeness

# Проверка целостности всех модулей
for module in "${STANDARD_MODULES[@]}"; do
    check_module_completeness $module
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
if [[ $COMMAND = 'install' ]]; then
    extend_modules_by_deps
    echo_added_modules
fi

# Объявления массивов опций для модулей
for module in "${STANDARD_MODULES[@]}"; do
    get_module_opts_var $module
    declare -A "$MODULE_OPTS_VAR"
done

# Записать опции из консоли в переменную, используемую в скриптах модуля
assign_module_opts

# Подключить конфиг (если задан)
require_conf

# Опции, заданные параллельно с конфигом, игнорируются
if [[ ! -z $CONF ]]; then
    check_redundant_options
fi

if [[ $COMMAND = 'purge' ]]; then
    # Проверка, существуют ли установленные модули, зависящие от удаляемых
    check_dependents
fi

# Проверить, какие из добавленных модулей уже установлены и удалить их из списков
if [[ $COMMAND = 'install' || $COMMAND = 'purge' ]]; then
    MODIFY=()
    NEW=()
    check_modules_status
    if [[ ${#MODULES[@]} -eq 0 ]]; then
        exit
    fi

    if [[ $COMMAND = 'install' && ${#NEW[@]} -gt 0 ]]; then
        echo "Modules that will be installed:"
        for m in "${NEW[@]}"; do
            echo " - $m"
        done
        confirm "Are you sure?"
    elif [[ $COMMAND = 'purge' ]]; then
        echo "Modules that will be purged:"
        for m in "${MODULES[@]}"; do
            echo " - $m"
        done
        confirm "Are you sure?"
    fi
fi

[[ $COMMAND = 'check' ]] && {
    declare -A MODULES_STATUS
}

# Собственно выполнение команды над модулями
for module in "${MODULES[@]}"; do
    execute_module_command $module $COMMAND
    [[ $COMMAND = 'check' ]] && {
        MODULES_STATUS[$module]=$INSTALLED
    }
done

[[ $COMMAND = 'check' ]] && {
    echo_modules_status
}
