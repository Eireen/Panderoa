#!/bin/bash

MODULES_FOLDER="../modules"

. ../conf.sh

function setdeps() {
	local module=$1
	MODULES[$module]=true
	. "$MODULES_FOLDER/$module/deps.sh"
	for d in "${DEPS[@]}"; do
		[[ ${!MODULES[@]} =~ $d ]] && {
			MODULES[$d]=true
		} || {
			echo "Module $d from dependencies of $module not found"
			exit 2
		}
		setdeps $d
	done
}

# Формирование списка устанавливаемых модулей
for module in "${!MODULES[@]}"; do

	if [[ ${MODULES[$module]} != true ]]; then
		continue
	fi

	# Подключение файла зависимостей модуля
	. "$MODULES_FOLDER/$module/deps.sh"

	# Добавление модулей из списка зависимостей в список установки
	for dep in "${DEPS[@]}"; do
		setdeps $dep
	done

done

echo ${!MODULES[*]}
echo ${MODULES[*]}

