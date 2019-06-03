#!/bin/bash

CWD=$(cd $(dirname $0) && pwd)

TFROOT=$CWD/../$1
DOMAIN=$2
TFVARS="-var root_domain=${DOMAIN}"

source $CWD/common.sh $TFROOT


if [ ! -e "$TFROOT/cert/id_rsa" ]; then
	echo "generate key pair for AWS...."
	ssh-keygen -m PEM -t rsa -b 4096 -N '' -f $TFROOT/cert/id_rsa
	echo "generate at $CWD/resources/cert/id_rsa. please preserve it in secure place"
fi

echo "use domain: ${DOMAIN}"

tf init -input=false
# tf state rm aws_route53_zone.latency-research-http2 
# tf import aws_route53_zone.latency-research-http2 Z23K2L6PFTIAZ8
# tf taint aws_autoscaling_group.latency-research-http2 
tf plan ${TFVARS} --out $TFROOT/exec.tfplan
tf apply $TFROOT/exec.tfplan
