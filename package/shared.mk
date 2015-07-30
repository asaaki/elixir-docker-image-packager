APPINFO_RUNNER = cd app && mix run --no-compile --no-deps-check --no-start -r ../tools/app_info.exs -e

APPNAME        = $(shell $(APPINFO_RUNNER) "IO.puts AppInfo.app_name")
APPVER         = $(shell $(APPINFO_RUNNER) "IO.puts AppInfo.app_version")
APPDIR         = $(shell pwd)/app

MIX_ENV       ?= prod
RELEASE        = releases/$(APPVER)/$(APPNAME).tar.gz
RELEASE_FILE   = $(APPDIR)/rel/$(APPNAME)/$(RELEASE)

STAGE_DIR      = /stage
TARBALLS_DIR   = $(STAGE_DIR)/tarballs
ROOTFS_TARBALL = $(TARBALLS_DIR)/rootfs.tar.gz
