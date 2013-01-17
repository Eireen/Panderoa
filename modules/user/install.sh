#!/bin/bash

. "$MODULES_FOLDER/user/conf.sh"

# Script to add a user to Linux system
if [ `id -u` -eq 0 ]; then
    egrep "^$LOGIN" /etc/passwd >/dev/null
    if [ $? -eq 0 ]; then
        echo "User $LOGIN already exists!"
        exit 1
    else
        CRYPTED_PASS=`mkpasswd $PASSWORD 12`
        useradd -m -p $CRYPTED_PASS $LOGIN
        EXIT_CODE=$?
        [ $EXIT_CODE -eq 0 ] && echo "User $LOGIN has been added to system!" || {
            echo "Failed to add a user!"
            exit $EXIT_CODE
        }
    fi
else
    echo "Only root may add a user to the system"
    exit 3
fi