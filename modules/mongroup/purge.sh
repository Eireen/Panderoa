#!/bin/bash

__namespace__() {

	purge_packs 'mongroup'

	dpkg -r mongroup

}; __namespace__