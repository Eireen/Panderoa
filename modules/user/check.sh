#!/bin/bash

INSTALLED=false

grep $LOGIN /etc/passwd > /dev/null && {
	INSTALLED=true
}