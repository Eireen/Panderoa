#!/bin/bash

__namespace__() {

	require_packs 'mysql'
	packs_to_remove 'mysql'
	purge_packs

}; __namespace__