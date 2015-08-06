# APPINFO_RUNNER = cd app && mix run --no-compile --no-deps-check --no-start -r ../tools/app_info.exs -e
APPINFO_RUNNER = $(TOOLS_DIR)/app_info

BUILD_DIR      = /build
TOOLS_DIR      = $(BUILD_DIR)/tools

APPDIR         = $(BUILD_DIR)/app
APPNAME        = $(shell $(APPINFO_RUNNER) name)
APPVER         = $(shell $(APPINFO_RUNNER) version)

MIX_ENV       ?= prod
RELEASE        = releases/$(APPVER)/$(APPNAME).tar.gz
RELEASE_FILE   = $(APPDIR)/rel/$(APPNAME)/$(RELEASE)

STAGE_DIR      = /stage
TARBALLS_DIR   = $(STAGE_DIR)/tarballs
ROOTFS_TARBALL = $(TARBALLS_DIR)/rootfs.tar.gz
