#!/bin/bash

CWD=$(cd $(dirname $0) && pwd)

TFROOT=$CWD/../$1
DOMAIN=$2
TFVARS="-var root_domain=${DOMAIN}"

TERMINAL= source $CWD/common.sh $TFROOT
input=$(tf state show -no-color $3)
target=$4
regex="$target[[:space:]]*=[[:space:]]*\"(.*)\""

if [[ $input =~ $regex ]]; then
    echo "${BASH_REMATCH[1]}"
else
    exit 1
fi
