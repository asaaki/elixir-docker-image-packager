# app release builder

include package/shared.mk

IN_APP_DIR = cd $(APPDIR) &&

all: info release postinfo

info:
	@echo "Build app release ..."

postinfo:
	@echo "... finished!"

release: $(RELEASE_FILE)

$(RELEASE_FILE): app-compile
	$(IN_APP_DIR) MIX_ENV=$(MIX_ENV) mix release

app-compile: app-deps
	$(IN_APP_DIR) MIX_ENV=$(MIX_ENV) mix compile

app-deps:
	$(IN_APP_DIR) mix deps.get
