# OpenRatio — build helpers. Run `make` to build a Release .app into build/OpenRatio.app.
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c
#
# Works with either a selected Xcode or just Command Line Tools + Xcode.app in /Applications
# (we point DEVELOPER_DIR at Xcode.app when xcode-select still points at the CLT).

APP_NAME        := OpenRatio
SCHEME          := OpenRatio
PROJECT         := $(APP_NAME).xcodeproj
CONFIG          ?= Release
BUILD_DIR       := build
DERIVED         := $(BUILD_DIR)/DerivedData
PRODUCT         := $(DERIVED)/Build/Products/$(CONFIG)/$(APP_NAME).app
SIGNING_IDENTITY ?= -

XCODE_APP := /Applications/Xcode.app/Contents/Developer
ifeq ($(shell xcode-select -p 2>/dev/null),/Library/Developer/CommandLineTools)
  ifneq ($(wildcard $(XCODE_APP)),)
    export DEVELOPER_DIR := $(XCODE_APP)
  endif
endif

XCB := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIG) -derivedDataPath $(DERIVED)

# Resources/Info.plist holds $(MARKETING_VERSION) unsubstituted, so read the real
# value from the project spec, which is where it is actually defined.
VERSION := $(shell awk -F'"' '/MARKETING_VERSION:/{print $$2; exit}' project.yml)
DMG := $(BUILD_DIR)/$(APP_NAME)-$(VERSION).dmg

.PHONY: all project build app run test clean release open dmg dmg-background dist

all: app

## Regenerate OpenRatio.xcodeproj from project.yml (needs `brew install xcodegen`).
project:
	xcodegen generate

$(PROJECT): project.yml
	@if command -v xcodegen >/dev/null 2>&1; then xcodegen generate; else echo "xcodegen not installed; using committed $(PROJECT)"; fi

build: $(PROJECT)
	$(XCB) CODE_SIGN_IDENTITY="$(SIGNING_IDENTITY)" build | grep -E "error|warning: |BUILD" || true
	@test -d "$(PRODUCT)" || (echo "Build failed — see full log with: $(XCB) build" && exit 1)

## Copy the built app to build/OpenRatio.app
app: build
	rm -rf $(BUILD_DIR)/$(APP_NAME).app
	cp -R "$(PRODUCT)" $(BUILD_DIR)/$(APP_NAME).app
	@echo "→ $(BUILD_DIR)/$(APP_NAME).app"

## Build and launch (kills a running instance first)
run: app
	-pkill -x $(APP_NAME) 2>/dev/null; sleep 0.3
	open $(BUILD_DIR)/$(APP_NAME).app

open: run

test: $(PROJECT)
	$(XCB) CODE_SIGN_IDENTITY="-" test 2>&1 | grep -E "Test Suite|Test Case|error|passed|failed|BUILD" | tail -40

## Zip for distribution (build/OpenRatio.zip). Set SIGNING_IDENTITY="Developer ID Application: ..." to sign for real.
release: app
	rm -f $(BUILD_DIR)/$(APP_NAME).zip
	ditto -c -k --keepParent $(BUILD_DIR)/$(APP_NAME).app $(BUILD_DIR)/$(APP_NAME).zip
	@echo "→ $(BUILD_DIR)/$(APP_NAME).zip"

## Styled disk image with the drag-to-Applications window (build/OpenRatio-VERSION.dmg).
## Needs `pip3 install dmgbuild` (no Finder scripting, so it also works in CI).
dmg: app
	@command -v dmgbuild >/dev/null 2>&1 || { echo "dmgbuild not found. Run: pip3 install dmgbuild"; exit 1; }
	@test -f Resources/dmg/background.tiff || $(MAKE) dmg-background
	rm -f "$(DMG)"
	dmgbuild -s scripts/dmg_settings.py -D app=$(BUILD_DIR)/$(APP_NAME).app -D root="$(CURDIR)" \
		"$(APP_NAME) $(VERSION)" "$(DMG)"
	@echo "→ $(DMG)"
	@shasum -a 256 "$(DMG)"

## Redraw the disk image background (committed, so this is only needed after
## editing scripts/make_dmg_background.py). Needs `pip3 install Pillow`.
dmg-background:
	python3 scripts/make_dmg_background.py

## Everything a release needs: the disk image, the zip, and their checksums.
dist: dmg release
	@echo
	@shasum -a 256 $(DMG) $(BUILD_DIR)/$(APP_NAME).zip

## Render every panel state to PNGs in build/snapshots (used for README + visual QA)
snapshots: app
	rm -rf $(BUILD_DIR)/snapshots && mkdir -p $(BUILD_DIR)/snapshots
	$(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS/$(APP_NAME) --snapshot $(BUILD_DIR)/snapshots
	@ls $(BUILD_DIR)/snapshots

clean:
	rm -rf $(BUILD_DIR)
