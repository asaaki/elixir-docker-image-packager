# container orchestration

include package/app-config.mk

DOCKERFILES        = dockerfiles
DOCKERFILE_STAGE   = $(DOCKERFILES)/Dockerfile.stage
DOCKERFILE_RELEASE = $(DOCKERFILES)/Dockerfile.release
IMG_NAME_STAGE     = local/stage-image
IMG_NAME_RELEASE   = local/release-image
DOCKER_BUILD       = docker build
DOCKER_RUN         = docker run --rm

# Docker volumes:
HOST_HEX_PKG_DIR  = $(HOME)/.hex/packages
HEX_PKG_DIR       = /root/.hex/packages
HOST_TARBALLS_DIR = $(shell pwd)/tarballs
TARBALLS_DIR      = /stage/tarballs
STAGE_VOLUMES   = \
	-v=$(HOST_HEX_PKG_DIR):$(HEX_PKG_DIR) \
	-v=$(HOST_TARBALLS_DIR):$(TARBALLS_DIR)

all: build

build: clean build-release image-info

image-info:
	@docker images

build-stage:
	$(DOCKER_BUILD) -f $(DOCKERFILE_STAGE) -t $(IMG_NAME_STAGE) .

build-package: build-stage
	$(DOCKER_RUN) $(STAGE_VOLUMES) $(IMG_NAME_STAGE)

$(DOCKERFILE_RELEASE):
	sed "s/###APPNAME###/$(APPNAME)/" $@.template > $@

build-release: $(DOCKERFILE_RELEASE) build-package
	$(DOCKER_BUILD) -f $(DOCKERFILE_RELEASE) -t $(IMG_NAME_RELEASE) .

run-release:
	-$(DOCKER_RUN) -it $(IMG_NAME_RELEASE)

clean: clean-$(DOCKERFILE_RELEASE) clean-tarballs

clean-$(DOCKERFILE_RELEASE):
	@rm -rf $(DOCKERFILE_RELEASE)

clean-tarballs:
	@rm -rf $(HOST_TARBALLS_DIR)/*

### Helpers

remove: remove-containers remove-untagged-images

remove-containers:
	-docker rm `docker ps -a -q`

remove-untagged-images:
	-docker rmi `docker images | awk '$$2 ~ /none/ {print $$3}'`
