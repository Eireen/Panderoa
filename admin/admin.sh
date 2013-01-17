#!/bin/bash

# Выполнение заданной операции над модулем
# Параметры: operation module
# function process() {
# 	if [ $# -eq 0 ]; then
# 		echo "Function process() must be given at least 2 parameters"
# 		exit 6
# 	fi
# 	local operation=$1
# 	if [ $# -eq 1 ]; then
# 		# Применить эту операцию ко всем модулям
# 	else
# 		# Получить список модулей

# 	fi
# }

echo $#
MODULE=$2

[[ ${!MODULES[@]} =~ $MODULE ]] || {
	echo "Module $MODULE not found"
	exit 3
}

MODULE_FOLDER="$MODULES_FOLDER/$MODULE"

if [ ! -d $MODULE_FOLDER ]; then
	echo "Directory $MODULE_FOLDER doesn't exist"
	exit 4;
fi

case $1 in
	"install")
		;;
	"purge")
		PURGE_FILE="$MODULE_FOLDER/purge.sh"
		if [ -f $PURGE_FILE ]; then
			. $PURGE_FILE
		else
			echo "File $PURGE_FILE not found"
			exit 4
		fi
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