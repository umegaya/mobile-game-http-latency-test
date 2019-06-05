#!/bin/bash

CWD=$(cd $(dirname $0) && pwd)

TFROOT=$CWD/..
DOMAIN=$1
TFVARS="-var root_domain=${DOMAIN}"

TERMINAL= source $CWD/common.sh $TFROOT
if [ -z "$2" ]; then
    tf state list
	exit 0
fi
input=$(tf state show -no-color $2)
target=$3
if [ -z "$target" ]; then
	echo "$input"
	exit 0
fi
regex="$target[[:space:]]*=[[:space:]]*\"(.*)\""

if [[ $input =~ $regex ]]; then
    echo "${BASH_REMATCH[1]}"
else
    exit 1
fi
