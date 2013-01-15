#!/bin/bash

. ./conf.sh

# Script to add a user to Linux system
if [ `id -u` -eq 0 ]; then
    egrep "^$LOGIN" /etc/passwd >/dev/null
    if [ $? -eq 0 ]; then
        echo "User $LOGIN already exists!"
        exit 1
    else
        CRYPTED_PASS=`mkpasswd $PASSWORD 12`
        echo $CRYPTED_PASS
        useradd -m -p $CRYPTED_PASS $LOGIN
        [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
    fi
else
    echo "Only root may add a user to the system"
    exit 2
fi