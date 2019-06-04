# args
TYPE=#http2,grpc
STATE=#terraform resource path
IMAGE=#docker image 

# tfvars declaration
DOMAIN=#your.domain.com


define tf 
	@[ ! -z "$(TYPE)" ] || (echo "TYPE is not set" && exit 1)
	@[ ! -z "$(DOMAIN)" ] || (echo "DOMAIN is not set" && exit 1)
	bash $(CURDIR)/tools/$1.sh $(TYPE) $(DOMAIN) $2
endef

console:
	$(call tf,console,$(STATE))

deploy:
	$(call tf,deploy,$(IMAGE))

# caution: before destroy, make sure that unprotect lb and remove s3 bucket for logging 
destroy:
	$(call tf,destroy)

setup:
	$(call tf,setup)

graph:
	$(call tf,graph)