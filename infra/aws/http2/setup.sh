#!/bin/bash

set -e

AWS_CLI_VERSION=758eef2a762bc3a4d7df2a41f655b7a884b492fa
CWD=$(cd $(dirname $0) && pwd)

aws() {
	docker run --rm -ti \
		-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
		-e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
		governmentpaas/awscli:$AWS_CLI_VERSION aws $@
}

#AWS_ALB_SUBNETS=$(aws ec2 describe-subnets | jq .Subnets[].SubnetId)

#echo $AWS_ALB_SUBNETS

#aws elbv2 create-load-balancer --name my-load-balancer \
#	--subnets subnet-12345678 subnet-23456789 --security-groups sg-12345678

tf() {
	docker run -i -t -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
		-e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
		-v /Users:/Users \
		-v $CWD:/tf -w /tf/resources hashicorp/terraform:light $@
}

if [ ! -e "$CWD/resources/cert/id_rsa" ]; then
	echo "generate key pair for AWS...."
	ssh-keygen -m PEM -t rsa -b 4096 -N '' -f $CWD/resources/cert/id_rsa
	echo "generate at $CWD/resources/cert/id_rsa. please preserve it in secure place"
fi

tf init -input=false
# tf taint aws_autoscaling_group.latency-research-http2 
tf plan --out $CWD/exec.tfplan
tf apply $CWD/exec.tfplan
