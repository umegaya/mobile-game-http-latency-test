NAME=latency-research-websv
IMAGE=

.PHONY: build
build:
	npm run-script build

image: build
	docker build -t $(IMAGE) build

sv: 
	-@docker kill $(NAME)
	-@docker rm $(NAME)
	docker run --name=$(NAME) -d -p 80:80 $(IMAGE) node index.js

fg:
	docker run --init --rm -ti -p 80:80 $(IMAGE) node index.js

deploy_http2:
	bash ../infra/aws/http2/deploy.sh $(IMAGE)
