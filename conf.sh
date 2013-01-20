#!/bin/bash

declare -A MODULES

MODULES=(
	[user]=true
	[ftp]=false
	[other]=false
	[mysql]=false
	[node]=false
	[nginx]=false
)

ORDERED_MODULES=(
	user
	ftp
	other
	mysql
	node
	nginx
)