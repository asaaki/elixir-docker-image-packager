include package/shared.mk

DOCKER_IMPORT      = docker import
DOCKER_TAG         = docker tag
ifdef RELEASE_NAME
IMAGE_NAME         = $(RELEASE_NAME):$(RELEASE_TAG)
else
RELEASE_PREFIX    ?= local
RELEASE_TAG       ?= $(APPVER)
IMAGE_NAME         = $(RELEASE_PREFIX)/$(APPNAME):$(RELEASE_TAG)
endif
IMAGE_NAME_LATEST  = $(IMAGE_NAME:$(RELEASE_TAG)=latest)
RELEASE_SETTINGS   = --change 'CMD trap exit TERM; /app/bin/$(APPNAME) foreground & wait'

all: build build-info

build:
	cat $(ROOTFS_TARBALL) | \
	$(DOCKER_IMPORT) $(RELEASE_SETTINGS) - $(IMAGE_NAME)
	@$(DOCKER_TAG) $(IMAGE_NAME) $(IMAGE_NAME_LATEST)

build-info:
	@echo Your docker image is ready.
	@echo
	@echo Image name: $(IMAGE_NAME)
	@echo Also tagged as latest: $(IMAGE_NAME_LATEST)
	@echo
	@echo Test it with:
	@echo " docker run --rm -it $(IMAGE_NAME)"
	@echo
	@echo For a phoenix app:
	@echo " docker run --rm -it -e "PORT=4000" -p 4000:4000 $(IMAGE_NAME)"
	@echo
