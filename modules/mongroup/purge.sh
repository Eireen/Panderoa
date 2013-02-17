#!/bin/bash

__namespace__() {

    purge_packs 'mongroup'

    dpkg -r mongroup

    dpkg -r mon

}; __namespace__