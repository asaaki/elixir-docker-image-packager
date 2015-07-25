# container orchestration

include package/app-config.mk

DOCKERFILES        = dockerfiles
DOCKERFILE_STAGE   = $(DOCKERFILES)/Dockerfile.stage
IMG_NAME_STAGE     = local/stage-image
IMG_NAME_RELEASE   = local/release-image
DOCKER_BUILD       = docker build --rm
DOCKER_RUN         = docker run --rm
DOCKER_IMPORT      = docker import

# Docker volumes:
HOST_HEX_PKG_DIR  = $(HOME)/.hex/packages
HEX_PKG_DIR       = /root/.hex/packages
HOST_TARBALLS_DIR = $(shell pwd)/tarballs
TARBALLS_DIR      = /stage/tarballs
STAGE_VOLUMES   = \
	-v $(HOST_HEX_PKG_DIR):$(HEX_PKG_DIR) \
	-v $(HOST_TARBALLS_DIR):$(TARBALLS_DIR)

RELEASE_ROOTFS   = $(HOST_TARBALLS_DIR)/rootfs.tar.gz
RELEASE_SETTINGS = --change 'CMD trap exit TERM; /app/bin/$(APPNAME) foreground & wait'

all: build

build: clean build-release image-info

image-info:
	@docker images

build-stage:
	$(DOCKER_BUILD) -f $(DOCKERFILE_STAGE) -t $(IMG_NAME_STAGE) .

build-package: build-stage
	$(DOCKER_RUN) $(STAGE_VOLUMES) $(IMG_NAME_STAGE)

build-release: build-package
	cat $(RELEASE_ROOTFS) | \
	$(DOCKER_IMPORT) $(RELEASE_SETTINGS) - $(IMG_NAME_RELEASE)

run-release:
	-$(DOCKER_RUN) -it $(IMG_NAME_RELEASE)

clean: clean-tarballs

clean-tarballs:
	@rm -rf $(HOST_TARBALLS_DIR)/*

### Helpers

remove: remove-containers remove-untagged-images

remove-containers:
	-docker rm `docker ps -a -q`

remove-untagged-images:
	-docker rmi `docker images | awk '$$2 ~ /none/ {print $$3}'`

doctoc:
	@doctoc README.md --github --maxlevel 4 --title '## TOC'
