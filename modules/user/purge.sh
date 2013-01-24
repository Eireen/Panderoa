#!/bin/bash

userdel -r $LOGIN

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
	echo "User $LOGIN was successfully removed from system."
	exit $EXIT_CODE
else
	echo "Failed to remove a user!"
	exit $EXIT_CODE
fi