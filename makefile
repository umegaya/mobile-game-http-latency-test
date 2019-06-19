# args
STATE=#terraform resource path
IMAGE=#docker image
GRPC_HOST=localhost:50051
DEST=

# tfvars declaration
DOMAIN=#your.domain.name


aws:
	make -C infra/aws setup DOMAIN=$(DOMAIN)

aws-rm:
	make -C infra/aws destroy DOMAIN=$(DOMAIN)

aws-deploy:
	make -C infra/aws deploy IMAGE=$(IMAGE) DOMAIN=$(DOMAIN)

aws-console:
	make -C infra/aws console STATE=$(STATE) DOMAIN=$(DOMAIN)

aws-grpc:
	@bash ./server/tools/measure.sh $(GRPC_HOST) ./server/proto/api.proto

aws-show:
	make -C infra/aws show STATE=$(STATE) DOMAIN=$(DOMAIN)


build:
	make -C server image IMAGE=$(IMAGE)

update_mhttp:
	rsync -av --exclude='*.meta' --exclude='iOS/*' client/Assets/Plugins/Mhttp/ $(DEST)