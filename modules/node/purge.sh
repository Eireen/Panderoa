#!/bin/bash

__namespace__() {

	require_packs 'node'
	purge_packs

	dpkg -r nodejs

}; __namespace__