#!/bin/bash

__namespace__() {

	require_packs 'node'
	packs_to_remove 'node'
	purge_packs

	dpkg -r 'nodejs'

}; __namespace__