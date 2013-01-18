#!/bin/bash

# Выполнение заданной операции над модулем
# Параметры: operation module1 [module2 [...]]
function process() {
	if [ $# -eq 0 ]; then
		echo "Function process() must be given at least 2 parameters"
		exit 6
	fi
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

			if [ ! -d $MODULE_FOLDER ]; then
			echo "Directory $MODULE_FOLDER doesn't exist"
			exit 4;
			fi

			OPERATION_FILE="$MODULE_FOLDER/$operation.sh"
			if [ -f $OPERATION_FILE ]; then
				. $OPERATION_FILE
			else
				echo "File $OPERATION_FILE not found"
				exit 4
			fi

			shift

		done
	fi
}

case $1 in
	"install")
		;;
	"purge")
		read -n 1 -p "Remove given modules? (y/[a]): " SURE 
		[ "$SURE" = "y" ] || {
			echo 
			exit 0
		}
		echo "" 1>&2
		process $*
		;;
	"update")
		;;
	"upgrade")
		;;
	* )
		echo "Invalid parameter: $1"
		exit 5
		;;
esac