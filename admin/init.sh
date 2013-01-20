#!/bin/bash

# Подключение файла зависимостей модуля
# Параметры: 
# 1 - module
function getdeps() {
	checkNumArgs 1 $# "Function getdeps() requires at least 1 argument"
	local module=$1
	DEPS_FILE="$MODULES_FOLDER/$module/deps.sh"
	checkFile $DEPS_FILE
	. $DEPS_FILE
}

# Проверка модулей из списка зависимостей
# Параметры: 
# 1 - module
function checkdeps() {
	checkNumArgs 1 $# "Function checkdeps() must be given at least 1 argument"
	local module=$1
	MODULES[$module]=true
	getdeps $module
	for d in "${DEPS[@]}"; do
		[[ ${!MODULES[@]} =~ $d ]] && {
			MODULES[$d]=true
		} || {
			echo "Module $d from dependencies of $module not found"
			exit 1
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
	checkFile $INSTALL_FILE

	. $INSTALL_FILE

done