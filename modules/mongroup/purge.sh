#!/bin/bash

__namespace__() {

	require_packs 'mongroup'
	packs_to_remove 'mongroup'
	purge_packs

	dpkg -r mongroup

}; __namespace__