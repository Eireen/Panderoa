#!/bin/bash

CONFIG_FILE="$MODULES_FOLDER/user/conf.sh"
checkFile $CONFIG_FILE
. $CONFIG_FILE

# Установка необходимых пакетов
dpkg -s whois >/dev/null 2>&1 || {
    echo "Installing package 'whois'..."
    apt-get install -y whois || {
        echo "Failed to install package 'whois'. Exit."
        exit 1
    }
}

# Script to add a user to Linux system
egrep "^$LOGIN" /etc/passwd >/dev/null && {
    echo "User $LOGIN already exists!"
    exit 1
} || {
    CRYPTED_PASS=`mkpasswd $PASSWORD 12`
    useradd -m -p $CRYPTED_PASS $LOGIN && echo "User '$LOGIN' has been successfully added to system!" || {
        echo "Failed to add a user!"
        exit 1
    }
}
