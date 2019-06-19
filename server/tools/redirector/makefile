image:
	docker build -t $(IMAGE) .

run:
	@-docker kill redirector
	@-docker rm redirector
	docker run -d --name redirector -e REDIRECT_TO=$(REDIRECT_TO) -p 8080:8080 $(IMAGE)