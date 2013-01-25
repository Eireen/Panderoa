#!/bin/bash

# Checks required number of arguments
# Parameters:
# 1 - required number of arguments
# 2 - actual number of arguments
# 3 - error message
# 4 - usage message
function checkNumArgs() {
	if [[ $# -lt 2 ]]; then
		echo "Error: function checkNumArgs() requires at least 2 arguments"
		exit 1
	fi
	if [[ $1 -gt $2 ]]; then
		if [[ $# -gt 2 ]]; then
			echo "$3"
		else
			echo "Invalid number of arguments: $2, expected $1"
		fi
		if [[ $# -gt 3 ]]; then
			echo "$4"
		fi
		exit 1
	fi
}

# Confirmation from user
# Parameters: 
# 1 - question
# 2 - message printing if not sure
function confirm() {
	checkNumArgs 1 $# "Error: function confirm() requires at least 1 argument"
	read -n 1 -p "$1" SURE 
		[[ "$SURE" = y ]] || {
			echo 
			if [[ $# -gt 1 ]]; then
				echo "$2"
			fi
			exit 0
		}
		echo "" 1>&2
}

# Checks if directory exists
# Parameters:
# 1 - directory
# 2 - message printing if not exist
function checkDir() {
	checkNumArgs 1 $# "Error: function checkDir() requires at least 1 argument"
	if [ ! -d "$1" ]; then
		if [[ $# -gt 1 ]]; then
			echo "$2"
		else
			echo "Directory $1 doesn't exist"
		fi
		exit 1
	fi
}

# Checks if file exists
# Parameters:
# 1 - file
# 2 - message printing if not exist
function checkFile() {
	checkNumArgs 1 $# "Error: function checkFile() requires at least 1 argument"
	if [ ! -f "$1" ]; then
		if [[ $# -gt 1 ]]; then
			echo "$2"
		else
			echo "File $1 doesn't exist"
		fi
		exit 1
	fi
}



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

# Рекурсия для checkdeps()
# Параметры: 
# 1 - module
# 2 - check in general list
function checkdeps_recursion() {
	checkNumArgs 1 $# "Function checkdeps_recursion() must be given at least 1 argument"
	local module=$1
	MODULES[$module]=true
	getdeps $module
	for d in "${DEPS[@]}"; do
		[[ ${!MODULES[@]} =~ $d ]] && {
			if [[ true != ${MODULES[$d]} ]]; then
				NEW_LIST[${#NEW_LIST[@]}]=true
				if [[ $# -gt 1 ]]; then
					MODULES[$d]=true
				fi
			fi
		} || {
			echo "Module $d from dependencies of $module not found"
			exit 1
		}
		checkdeps $d
	done
}

# Проверка модулей из списка зависимостей
# Параметры:
# 1 - module
# 2 - check in general list
# Возвращает:
# NEW_LIST - список недостающих модулей
function checkdeps() {
	checkNumArgs 1 $# "Function checkdeps() must be given at least 1 argument"
	NEW_LIST=()
	checkdeps_recursion $*
}
