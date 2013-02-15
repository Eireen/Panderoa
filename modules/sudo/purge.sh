#!/bin/bash

__namespace__() {

	require_packs 'sudo'
	packs_to_remove 'sudo'
	purge_packs

	rm /etc/sudoers

}; __namespace__