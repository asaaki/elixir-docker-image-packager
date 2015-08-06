# container orchestration

DOCKER_BUILD      ?= docker build --rm --pull
DOCKER_RUN        ?= docker run --rm --privileged
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
	-v $(DOCKER):/usr/bin/docker
MIX_ENV           ?= prod
RELEASE_ENV        = -e "MIX_ENV=$(MIX_ENV)"
PREFIX            ?= local
ifdef NAME
RELEASE_ENV       += -e "RELEASE_NAME=$(NAME)"
else
RELEASE_ENV       += -e "RELEASE_PREFIX=$(PREFIX)"
endif
ifdef TAG
RELEASE_ENV       += -e "RELEASE_TAG=$(TAG)"
endif
# false | true | only (no docker image)
TARBALL           ?= false
WITH_TARBALL       = $(if $(findstring $(TARBALL), true only),true,false)
ifeq ($(WITH_TARBALL),true)
STAGE_VOLUMES     += -v $(shell pwd)/tarballs:/stage/tarballs
endif
ifeq ($(TARBALL),only)
RELEASE_ENV       += -e "SKIP_IMAGE=true"
endif

all: check-app build

build: build-package remove-stage

check-app:
	@[ -d app ] || (echo "No 'app' directory present. Please create or move one."; exit 1)

build-stage:
	$(DOCKER_BUILD) -f $(DOCKERFILE_STAGE) -t $(IMG_NAME_STAGE) .

build-package: build-stage
	$(DOCKER_RUN) $(STAGE_VOLUMES) $(RELEASE_ENV) $(IMG_NAME_STAGE)

enter-stage: build-stage
	$(DOCKER_RUN) $(STAGE_VOLUMES) $(RELEASE_ENV) -ti $(IMG_NAME_STAGE) /bin/sh

remove-stage:
	@$(DOCKER) rmi $(IMG_NAME_STAGE) >/dev/null

### Helpers

remove: remove-containers remove-untagged-images

remove-containers:
	-docker rm `docker ps -a -q`

remove-untagged-images:
	-docker rmi `docker images | awk '$$2 ~ /none/ {print $$3}'`

doctoc:
	@doctoc README.md --github --maxlevel 4 --title '## TOC'
