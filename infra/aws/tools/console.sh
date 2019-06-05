#!/bin/bash

CWD=$(cd $(dirname $0) && pwd)

TFROOT=$CWD/..
DOMAIN=$1
TFVARS="-var root_domain=${DOMAIN}"

if [ -z "$2" ]; then
    source $CWD/common.sh $TFROOT
    tf console
else
    TERMINAL= source $CWD/common.sh $TFROOT
    echo "$2" | tf console
fi
