#!/bin/bash

# Выполнение заданной операции над модулем
# Параметры: 
# 1 - operation
# 2 - module1 [module2 [...]]
function process() {
	checkNumArgs 1 $# "Error: function process() requires at least 1 argument"
	local operation=$1
	if [ $# -eq 1 ]; then
		# Применить эту операцию ко всем модулям
		:
	else
		# Применить эту операцию к заданному списку модулей
		shift
		until [[ -z "$1" ]]; do
			local module=$1

			[[ ${!MODULES[@]} =~ $module ]] || {
				echo "Module $module not found"
				exit 3
			}
			
			MODULE_FOLDER="$MODULES_FOLDER/$module"
			checkDir $MODULE_FOLDER

			OPERATION_FILE="$MODULE_FOLDER/$operation.sh"
			checkFile $OPERATION_FILE
			. $OPERATION_FILE

			if [[ "check" = $operation ]]; then
				if [[ true = $INSTALLED ]]; then
					echo "Yes, module '$module' is installed"
				else
					echo "No, module '$module' is not installed"
				fi
			fi

			shift

		done
	fi
}

case $1 in
	"install")
		# Проверить и установить зависимости
		;;
	"purge")
		confirm "Remove given modules? (y/[a]): "
		process $*
		;;
	"update")
		;;
	"upgrade")
		;;
	"check")
		process $*
		;;
	* )
		echo "Invalid parameter: $1"
		exit 5
		;;
esac