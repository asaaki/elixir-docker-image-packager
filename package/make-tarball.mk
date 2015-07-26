# tarball builder

include package/shared.mk

ROOTFS         = $(STAGE_DIR)/rootfs
ROOTFS_BIN     = $(ROOTFS)/bin
ROOTFS_SH      = $(ROOTFS_BIN)/sh
ROOTFS_APP     = $(ROOTFS)/app
ROOTFS_APP_BIN = $(ROOTFS_APP)/bin

BUSYBOX             = /bin/busybox
SYSTEM_FILES        = $(shell ./tools/libdeps.exs 2>/dev/null)
SOURCE_FILES        = $(SYSTEM_FILES) $(BUSYBOX)
ROOTFS_SYSTEM_FILES = $(SOURCE_FILES:%=$(ROOTFS)%)

all: info tarball postinfo

info:
	@echo "Packaging your app ..."

postinfo:
	@echo "... finished!"

tarball: $(ROOTFS_TARBALL)

$(ROOTFS_TARBALL): $(TARBALLS_DIR) $(ROOTFS_SYSTEM_FILES) $(ROOTFS_SH) $(ROOTFS_APP_BIN)
	cd $(ROOTFS) && tar -czvf $@ .

$(TARBALLS_DIR): $(STAGE_DIR)
	mkdir -p $@

$(STAGE_DIR):
	mkdir -p $@

$(ROOTFS_SYSTEM_FILES): $(ROOTFS)%: $(ROOTFS)
	cp -vfa --parents $* $(ROOTFS)/

$(ROOTFS_SH): $(ROOTFS_BIN)
	/bin/busybox --install -s $(ROOTFS_BIN)

$(ROOTFS_BIN): $(ROOTFS)
	mkdir -p $@

$(ROOTFS): $(STAGE)
	mkdir -p $@

$(ROOTFS_APP_BIN): $(ROOTFS_APP)
	tar -xzf $(RELEASE_FILE) -C $(ROOTFS_APP)
	rm -rf $(ROOTFS_APP)/$(RELEASE)

$(ROOTFS_APP): $(ROOTFS)
		mkdir -p $@
