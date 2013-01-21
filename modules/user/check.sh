#!/bin/bash

CONFIG_FILE="$MODULES_FOLDER/user/conf.sh"
checkFile $CONFIG_FILE
. $CONFIG_FILE

INSTALLED=false

grep $LOGIN /etc/passwd > /dev/null && {
	INSTALLED=true
}