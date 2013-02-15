#!/bin/bash

USER_OPTS['login']=testuser
USER_OPTS['password']=testpass
USER_OPTS['sudoer']=yes

SUDO_OPTS['nopasswd']=yes

SSH_OPTS['port']=12345
SSH_OPTS['forbid-root']=yes

FTP_OPTS['disable-anonymous']=yes
FTP_OPTS['enable-local']=yes
FTP_OPTS['enable-write']=yes

NGINX_OPTS['auth']=yes
NGINX_OPTS['gzip-static']=yes