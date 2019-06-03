# args
TYPE=#http2,grpc
STATE=#terraform resource path

# tfvars declaration
ROOT_DOMAIN=#your.domain.com


define tf 
	@[ ! -z "$(TYPE)" ] || (echo "TYPE is not set" && exit 1)
	@[ ! -z "$(ROOT_DOMAIN)" ] || (echo "ROOT_DOMAIN is not set" && exit 1)
	bash $(CURDIR)/tools/$1.sh $(TYPE) $(ROOT_DOMAIN) $3
endef

console:
	$(call tf,console,$(STATE))

deploy:
	$(call tf,deploy)

# caution: before destroy, make sure that unprotect lb and remove s3 bucket for logging 
destroy:
	$(call tf,destroy)

setup:
	$(call tf,setup)

graph:
	$(call tf,graph)