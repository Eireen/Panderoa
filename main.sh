#!/bin/bash

. ./core.sh

# Проверка прав на выполнение
check_uid

# Проверка целостности проекта
check_project_integrity

# Разбор входных данных
parse_input $*

# Очистка списка модулей от повторяющихся элементов
trim_modules

# Расширение списка модулей зависимостями из deps-файлов
extend_modules_by_deps

# Проверка наличия добавленных модулей
if [[ ${#ADDED_MODULES[@]} -gt 0 ]]; then
	# Вывести на экран список добавленных модулей
	echo "Added "
fi


declare -p MODULES
declare -p ADDED_MODULES