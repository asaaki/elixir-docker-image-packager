# in-container package builder

include package/shared.mk

EXRM     = $(shell $(APPINFO_RUNNER) "IO.puts AppInfo.exrm")
EXRM_ERR = The project as no 'exrm' dependency. Cannot proceed further

all: image

image: tarball
	$(MAKE) -f package/make-image.mk

tarball: app-release
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
