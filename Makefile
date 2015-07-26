# container orchestration

DOCKER_BUILD      ?= docker build --rm
DOCKER_RUN        ?= docker run --rm
DOCKERFILES        = dockerfiles
DOCKERFILE_STAGE   = $(DOCKERFILES)/Dockerfile.stage
IMG_NAME_STAGE    ?= local/stage-image
HOST_HEX_PKG_DIR  ?= $(HOME)/.hex/packages
HEX_PKG_DIR        = /root/.hex/packages
DOCKER             = $(shell which docker)
DOCKER_SOCK        = /var/run/docker.sock
STAGE_VOLUMES      = \
	-v $(HOST_HEX_PKG_DIR):$(HEX_PKG_DIR) \
	-v $(DOCKER_SOCK):$(DOCKER_SOCK) \
	-v $(DOCKER):$(DOCKER)

all: build

build: build-package image-info

check-app:
	[ -d app ] || (echo "No 'app' directory present. Please create or move one.")

image-info:
	@docker images

build-stage:
	$(DOCKER_BUILD) -f $(DOCKERFILE_STAGE) -t $(IMG_NAME_STAGE) .

build-package: build-stage
	$(DOCKER_RUN) $(STAGE_VOLUMES) -ti --privileged $(IMG_NAME_STAGE)

enter-stage: build-stage
	$(DOCKER_RUN) $(STAGE_VOLUMES) -ti --privileged $(IMG_NAME_STAGE) /bin/sh

### Helpers

remove: remove-containers remove-untagged-images

remove-containers:
	-docker rm `docker ps -a -q`

remove-untagged-images:
	-docker rmi `docker images | awk '$$2 ~ /none/ {print $$3}'`

doctoc:
	@doctoc README.md --github --maxlevel 4 --title '## TOC'
