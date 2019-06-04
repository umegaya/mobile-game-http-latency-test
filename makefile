# args
TYPE=#http2,grpc
STATE=#terraform resource path
IMAGE=#docker image

# tfvars declaration
DOMAIN=#your.domain.com


aws:
	make -C infra/aws setup TYPE=$(TYPE) DOMAIN=$(DOMAIN)

aws-rm:
	make -C infra/aws destroy TYPE=$(TYPE) DOMAIN=$(DOMAIN)

aws-deploy:
	make -C infra/aws deploy TYPE=$(TYPE) IMAGE=$(IMAGE) DOMAIN=$(DOMAIN)

build:
	make -C server image IMAGE=$(IMAGE)

aws-console:
	make -C infra/aws console TYPE=$(TYPE) STATE=$(STATE) DOMAIN=$(DOMAIN)