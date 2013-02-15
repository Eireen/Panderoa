#!/bin/bash

__namespace__() {

    install_packs 'mysql'

    mysql_secure_installation

}; __namespace__