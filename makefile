# args
TYPE=#http2,grpc
STATE=#terraform resource path
IMAGE=#docker image
GRPC_HOST=localhost:50051

# tfvars declaration
DOMAIN=#your.domain.name


aws:
	make -C infra/aws setup TYPE=$(TYPE) DOMAIN=$(DOMAIN)

aws-rm:
	make -C infra/aws destroy TYPE=$(TYPE) DOMAIN=$(DOMAIN)

aws-deploy:
	make -C infra/aws deploy TYPE=$(TYPE) IMAGE=$(IMAGE) DOMAIN=$(DOMAIN)

aws-console:
	make -C infra/aws console TYPE=$(TYPE) STATE=$(STATE) DOMAIN=$(DOMAIN)

aws-grpc:
	@bash ./server/tools/measure.sh $(GRPC_HOST) ./server/proto/api.proto


build:
	make -C server image IMAGE=$(IMAGE)
