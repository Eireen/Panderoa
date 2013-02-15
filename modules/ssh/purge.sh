#!/bin/bash

__namespace__() {

	require_packs 'ssh'
	packs_to_remove 'ssh'
	purge_packs

}; __namespace__