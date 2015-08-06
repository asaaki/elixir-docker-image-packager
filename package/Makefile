# in-container package builder

include package/shared.mk

EXRM     = $(shell $(APPINFO_RUNNER) exrm)
EXRM_ERR = The project as no 'exrm' dependency. Cannot proceed further

export TIMESTAMP         := $(shell date -u +"%Y%m%d_%H%M%S")
export NAMED_TARBALL_DIR  = $(TARBALLS_DIR)/$(TIMESTAMP)
export NAMED_ROOTFS       = $(APPNAME)-$(APPVER).tar.gz
export NAMED_TARBALL      = $(NAMED_TARBALL_DIR)/$(NAMED_ROOTFS)
export LINKED_TARBALL     = $(TARBALLS_DIR)/$(NAMED_ROOTFS)

ifeq ($(SKIP_IMAGE),true)
all: tarball
	@echo "Only tarball created: $(subst $(STAGE_DIR)/,,$(NAMED_TARBALL))"
	@echo "Create your own docker image with 'docker import' command."
	@echo "See: <https://docs.docker.com/reference/commandline/import/>"
else
all: image
endif

image: $(NAMED_TARBALL)
	$(MAKE) -f package/make-image.mk

tarball: $(NAMED_TARBALL)

$(NAMED_TARBALL): app-release
	$(MAKE) -f package/make-tarball.mk

app-release: prerequisites
	$(MAKE) -f package/make-app.mk

prerequisites: exrm

exrm:
ifneq ($(EXRM),true)
	$(error $(EXRM_ERR))
else
	@echo exrm depenceny is present.
endif
