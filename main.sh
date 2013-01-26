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

# Проверка прав на выполнение
check_uid

# Проверка целостности проекта
check_project_integrity

# Разбор входных данных
parse_input $*

# Подключение файла конфигурации, если задан
require_conf

# Проверка наличия необходимых опций
check_options

# Очистка списка модулей от повторяющихся элементов
trim_modules

# Расширение списка модулей зависимостями из deps-файлов
extend_modules_by_deps

# Проверить, какие из добавленных модулей уже установлены и удалить их из списков
declare -A CHECKS
# - проверка с "обнуленными" опциями
save_options
OPTIONS=()
for module in "${ADDED_MODULES}"; do
	check_module $module
	CHECKS["$module"]=$INSTALLED
done
# - проверка с реальными опциями



#declare -p OPTIONS
#declare -p MODULES
#declare -p ADDED_MODULES