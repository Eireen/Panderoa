#!/bin/bash

__namespace__() {

	require_packs 'ftp'
	packs_to_remove 'ftp'
	purge_packs

}; __namespace__