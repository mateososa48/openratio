# Split — build helpers. Run `make` to build a Release .app into build/Split.app.
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c
#
# Works with either a selected Xcode or just Command Line Tools + Xcode.app in /Applications
# (we point DEVELOPER_DIR at Xcode.app when xcode-select still points at the CLT).

APP_NAME        := Split
SCHEME          := Split
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

.PHONY: all project build app run test clean release open

all: app

## Regenerate Split.xcodeproj from project.yml (needs `brew install xcodegen`).
project:
	xcodegen generate

$(PROJECT): project.yml
	@if command -v xcodegen >/dev/null 2>&1; then xcodegen generate; else echo "xcodegen not installed; using committed $(PROJECT)"; fi

build: $(PROJECT)
	$(XCB) CODE_SIGN_IDENTITY="$(SIGNING_IDENTITY)" build | grep -E "error|warning: |BUILD" || true
	@test -d "$(PRODUCT)" || (echo "Build failed — see full log with: $(XCB) build" && exit 1)

## Copy the built app to build/Split.app
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

## Zip for distribution (build/Split.zip). Set SIGNING_IDENTITY="Developer ID Application: ..." to sign for real.
release: app
	rm -f $(BUILD_DIR)/$(APP_NAME).zip
	ditto -c -k --keepParent $(BUILD_DIR)/$(APP_NAME).app $(BUILD_DIR)/$(APP_NAME).zip
	@echo "→ $(BUILD_DIR)/$(APP_NAME).zip"

## Render every panel state to PNGs in build/snapshots (used for README + visual QA)
snapshots: app
	rm -rf $(BUILD_DIR)/snapshots && mkdir -p $(BUILD_DIR)/snapshots
	$(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS/$(APP_NAME) --snapshot $(BUILD_DIR)/snapshots
	@ls $(BUILD_DIR)/snapshots

clean:
	rm -rf $(BUILD_DIR)
