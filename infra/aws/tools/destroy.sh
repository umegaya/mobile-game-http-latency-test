#!/bin/bash

CWD=$(cd $(dirname $0) && pwd)

TFROOT=$CWD/..
DOMAIN=$1
TFVARS="-var root_domain=${DOMAIN}"

source $CWD/common.sh $TFROOT

tf destroy ${TFVARS}