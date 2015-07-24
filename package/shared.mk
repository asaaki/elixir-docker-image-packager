include package/app-config.mk

APPDIR       = $(shell pwd)/app
MIX_ENV      = prod
RELEASE      = releases/$(APPVER)/$(APPNAME).tar.gz
RELEASE_FILE = $(APPDIR)/rel/$(APPNAME)/$(RELEASE)
