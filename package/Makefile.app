# app release builder

include package/shared.mk

all: info release postinfo

info:
	@echo "Build app release ..."

postinfo:
	@echo "... finished!"

release: $(RELEASE_FILE)

$(RELEASE_FILE): app-compile
	cd $(APPDIR) && MIX_ENV=$(MIX_ENV) mix release

app-compile: app-deps
	cd $(APPDIR) && MIX_ENV=$(MIX_ENV) mix compile

app-deps:
	cd $(APPDIR) && mix deps.get

libs:
	./libdeps.exs
