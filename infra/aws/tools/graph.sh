#!/bin/bash

CWD=$(cd $(dirname $0) && pwd)

TFROOT=$CWD/../$1
DOMAIN=$2
TFVARS="-var root_domain=${DOMAIN}"

source $CWD/common.sh $TFROOT

tf graph 