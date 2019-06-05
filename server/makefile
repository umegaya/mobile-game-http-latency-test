NAME=latency-research-websv
PORTS=-p 80:80 -p 50051:50051
IMAGE=

.PHONY: build
build:
	npm run-script build

image: build
	cat build/Dockerfile.tpl | sed s#__IMAGE_NAME__#$(IMAGE)_base#g > build/Dockerfile
	cp -r proto build/
	docker build -t $(IMAGE) build

base_image:
	cp ./package.json ./build/base/
	docker build -t $(IMAGE)_base build/base

sv: 
	-@docker kill $(NAME)
	-@docker rm $(NAME)
	docker run --name=$(NAME) -d $(PORTS) $(IMAGE) node index.js

fg:
	docker run --init --rm -ti $(PORTS) $(IMAGE) node index.js

protoc_image:
	docker build -t $(IMAGE)_protoc tools/protoc_image

define protoc
docker run --rm -ti \
	-v $(CURDIR)/proto:/proto \
	-v $3:/out \
	znly/protoc \
	--proto_path=/proto \
    --plugin=protoc-gen-grpc=/usr/bin/grpc_csharp_plugin \
    --$1_out=/out \
    --grpc_out=/out \
    $2
endef

proto_cs:
	$(call protoc,csharp,api.proto,$(CS_OUT))