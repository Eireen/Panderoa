#!/bin/bash

__namespace__() {

	require_packs 'mysql'
	install_packs

	mysql_secure_installation

}; __namespace__