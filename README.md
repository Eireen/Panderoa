# Panderoa

If you need to configure the web server, and you have nothing but a VPS with a newly installed Debian 6, 
you can use this tool to quickly install and configure all of the necessary programs only a single line. 
You can (and should :) change the scripts on your own, adding new modules and options or editing existing ones. 
Once customized tool can then be used to set up any VPS with Debian 6 from scratch for your needs.

## Installation

```bash
wget --no-check-certificate https://github.com/Eireen/Panderoa/archive/master.tar.gz
tar -xzvf master.tar.gz && rm master.tar.gz && cd Panderoa-master
```

## Usage

```bash
pand <command> <modules> [options]
```

## Commands

### install

Before the first installation, don't forget to run:
```bash
apt-get update
apt-get upgrade
```

### purge
### check

## Modules

### ftp

FTP server provided by [vsftpd](https://security.appspot.com/vsftpd.html)

Options
* disable-anonymous
* enable-local
* enable-write

### mongroup

Process monitor ([its repo](https://github.com/jgallen23/mongroup))

### mysql

Needs no introduction

Options
* remote-access

### nginx

Simple, fast and reliable web server ([site](http://nginx.org/en/))

Options
* auth
* gzip-static

### node

[Site](http://nodejs.org/)

### ssh

OpenSSH server

### sudo

Think you've heard about this thing

### user

If you need to add a new user to the system, `pand` will do it for you :)
