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
