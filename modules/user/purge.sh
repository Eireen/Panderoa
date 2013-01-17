#!/bin/bash

CONFIG_FILE="$MODULE_FOLDER/conf.sh"

if [ -f $CONFIG_FILE ]; then
	. $CONFIG_FILE
else
	echo "File $CONFIG_FILE not found"
	exit 4
fi

userdel -r $LOGIN

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
	echo "User $LOGIN was successfully removed from system."
	exit $EXIT_CODE
else
	echo "Failed to remove a user!"
	exit $EXIT_CODE
fi