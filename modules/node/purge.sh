#!/bin/bash

__namespace__() {

	purge_packs 'node'

	dpkg -r 'nodejs'

}; __namespace__