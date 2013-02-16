# Panderoa

If you need to configure the web server, but you do not have nothing but a VPS with a newly installed Debian 6, 
this tool will help you quickly set up and configure all of the needed programs only a single line. 
You can (and should :) change the scripts on your own, adding or changing the modules and options. 
Once customized tool can then be used to set up any VPS with Debian 6 "from scratch" for your needs.

## Installation

Coming soon

## Usage

```bash
pand <command> <modules> [options]
```

## Commands

### install
### purge
### check

## Modules

### ftp

FTP server provided by [vsftpd](https://security.appspot.com/vsftpd.html)

Options

- disable-anonymous
- enable-local
- enable-write

### mongroup

Process monitor ([its repo](https://github.com/jgallen23/mongroup))

### mysql

Needs no introduction

Options
- remote-access

### nginx

Simple, fast and reliable web server ([site](http://nginx.org/en/))

Options
- auth
- gzip-static

### node

[Site](http://nodejs.org/)

### ssh
### sudo
### user

If you need to add a new user to the system, `pand` will do it for you :)
