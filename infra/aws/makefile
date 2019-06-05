# args
STATE=#terraform resource path
IMAGE=#docker image 

# tfvars declaration
DOMAIN=#your.domain.com


define tf 
	@[ ! -z "$(DOMAIN)" ] || (echo "DOMAIN is not set" && exit 1)
	bash $(CURDIR)/tools/$1.sh $(DOMAIN) $2
endef

console:
	$(call tf,console,$(STATE))

deploy:
	$(call tf,deploy,$(IMAGE))

# caution: before destroy, make sure that unprotect lb and remove s3 bucket for logging 
# and destroy will not remove following, please remove them manually. 
# - placement group
# - key pair
# - iam roles
destroy:
	$(call tf,destroy)

setup:
	$(call tf,setup)

graph:
	$(call tf,graph)

show:
	$(call tf,show,$(STATE))