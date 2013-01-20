#!/bin/bash

# Подключение файла зависимостей модуля
# Параметры: module
function getdeps() {
	if [ $# -eq 0 ]; then
		echo "Function getdeps() must be given at least 1 parameter"
		exit 6
	fi
	local module=$1
	DEPS_FILE="$MODULES_FOLDER/$module/deps.sh"
	if [ -f $DEPS_FILE ]; then
		. $DEPS_FILE
	else
		DEPS=()
	fi
}

# Проверка модулей из списка зависимостей
# Параметры: module
function checkdeps() {
	if [ $# -eq 0 ]; then
		echo "Function getdeps() must be given at least 1 parameter"
		exit 6
	fi
	local module=$1
	MODULES[$module]=true
	getdeps $module
	for d in "${DEPS[@]}"; do
		[[ ${!MODULES[@]} =~ $d ]] && {
			MODULES[$d]=true
		} || {
			echo "Module $d from dependencies of $module not found"
			exit 2
		}
		checkdeps $d
	done
}

# Формирование списка устанавливаемых модулей
for module in "${!MODULES[@]}"; do
	if [[ ${MODULES[$module]} != true ]]; then
		continue
	fi
	getdeps $module
	for dep in "${DEPS[@]}"; do
		checkdeps $dep
	done
done

# Вывод результирующего списка установки
echo "========= INSTALLATION LIST =========="
for module in "${!MODULES[@]}"; do
	echo $module = ${MODULES[$module]}
done
echo "======================================"

confirm "Install these modules? (y/[a]): "

# Установка
echo "============ INSTALLATION ============"
for module in "${ORDERED_MODULES[@]}"; do

	if [ ${MODULES[$module]} != true ]; then
		continue
	fi

	echo " ‒ Installing module $module..."

	INSTALL_FILE="$MODULES_FOLDER/$module/install.sh"

	if [ -f $INSTALL_FILE ]; then
		. $INSTALL_FILE
	else
		echo "File $INSTALL_FILE for module $module not found"
		exit 4
	fi

done