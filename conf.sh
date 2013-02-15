#!/bin/bash

SUDO_OPTS['nopasswd']=yes

USER_OPTS['login']=bright
USER_OPTS['password']=bright
USER_OPTS['sudoer']=yes

SSH_OPTS['port']=12345
SSH_OPTS['forbid-root']=yes

FTP_OPTS['disable-anonymous']=yes
FTP_OPTS['enable-local']=yes
FTP_OPTS['enable-write']=yes

NGINX_OPTS['auth']=yes
NGINX_OPTS['gzip-static']=yes