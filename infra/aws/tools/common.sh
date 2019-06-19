#!/bin/bash

TFROOT=$1
TERMINAL=-t

tf() {
	docker run -i $TERMINAL -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
		-e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
		-v /Users:/Users \
		-v $TFROOT/../resources:/resources \
		-v $TFROOT:/tf -w /tf \
		hashicorp/terraform:light $@
}

