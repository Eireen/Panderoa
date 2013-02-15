#!/bin/bash

__namespace__() {

	require_packs 'nginx'
	packs_to_remove 'nginx'
	purge_packs

	dpkg -r nginx

	rm -r /usr/local/nginx

}; __namespace__