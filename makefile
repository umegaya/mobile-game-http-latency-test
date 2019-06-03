# args
TYPE=#http2,grpc
STATE=#terraform resource path

# tfvars declaration
ROOT_DOMAIN=#your.domain.com


aws:
	make -C infra/aws setup TYPE=$(TYPE) STATE=$(STATE) ROOT_DOMAIN=$(ROOT_DOMAIN)

aws-rm:
	make -C infra/aws destroy TYPE=$(TYPE) STATE=$(STATE) ROOT_DOMAIN=$(ROOT_DOMAIN)

