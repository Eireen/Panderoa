#!/bin/bash

__namespace__() {

	require_packs 'nginx'
	purge_packs

	dpkg -r nginx

	rm -r /usr/local/nginx

}; __namespace__