#!/bin/bash

__namespace__() {

    purge_packs 'nginx'

    dpkg -r nginx

    rm -r /usr/local/nginx

}; __namespace__