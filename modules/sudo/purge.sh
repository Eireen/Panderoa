#!/bin/bash

__namespace__() {

    purge_packs 'sudo'

    rm /etc/sudoers

}; __namespace__