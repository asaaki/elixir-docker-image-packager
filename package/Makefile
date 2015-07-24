# in-container package builder

all: build

build: app-release tarball

app-release:
	$(MAKE) -f package/Makefile.app

tarball: app-release
	$(MAKE) -f package/Makefile.tarball
