#!/bin/bash

CWD=$(cd $(dirname $0) && pwd)

TFROOT=$CWD/../$1
DOMAIN=$2
TFVARS="-var root_domain=${DOMAIN}"

if [ -z "$3" ]; then
    source $CWD/common.sh $TFROOT
    tf console
else
    TERMINAL= source $CWD/common.sh $TFROOT
    echo "$3" | tf console
fi
