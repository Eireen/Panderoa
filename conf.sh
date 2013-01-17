#!/bin/bash

declare -A MODULES

MODULES=(
	[user]=false
	[ftp]=false
	[other]=true
	[mysql]=false
	[node]=true
	[nginx]=true
)

ORDERED_MODULES=(
	user
	ftp
	other
	mysql
	node
	nginx
)