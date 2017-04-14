.PHONY: all dist clean
BINARY_NAME := dataextractor
APP_NAME := streamsets-dataextractor
VERSION := 0.0.1
DIR=.
BuiltDate := `date +%FT%T%z`
BuiltRepoSha := `git rev-parse HEAD`

# Go setup
GO=go
TEST=go test

DEPENDENCIES := github.com/hpcloud/tail/... \
    github.com/BurntSushi/toml \
    github.com/satori/go.uuid \
    github.com/gorilla/websocket \
    github.com/eclipse/paho.mqtt.golang

EXECUTABLES :=dist/bin/$(BINARY_NAME)

# Build Binaries setting BuildInfo vars
LDFLAGS :=-ldflags "-X github.com/streamsets/dataextractor/container/common.Version=${VERSION} \
    -X github.com/streamsets/dataextractor/container/common.BuiltBy=$$USER \
    -X github.com/streamsets/dataextractor/container/common.BuiltDate=${BuiltDate} \
    -X github.com/streamsets/dataextractor/container/common.BuiltRepoSha=${BuiltRepoSha}"

# Package target
PACKAGE :=$(DIR)/dist/$(APP_NAME)-$$GOOS-$$GOARCH-$(VERSION).tar.gz

DEPENDENCIES_DIR := $(DEPENDENCIES)

.DEFAULT: dist

all: | $(EXECUTABLES)

$(DEPENDENCIES_DIR):
	@echo Downloading $@
	$(GO) get $@

dist/bin/$(BINARY_NAME): main.go $(DEPENDENCIES_DIR)

$(EXECUTABLES):
	$(GO) build $(LDFLAGS) -o $@ $<
	@cp -n -R $(DIR)/etc/ dist/etc 2>/dev/null || :
	@cp -n -R $(DIR)/data/ dist/data 2>/dev/null || :
	@mkdir -p dist/logs

test:
	$(TEST) -r -cover

clean:
	@echo Cleaning Workspace...
	rm -dRf dist

$(PACKAGE): all
	@echo Packaging Binaries...
	@mkdir -p tmp/$(APP_NAME)/bin
	@cp -R dist/bin/ tmp/$(APP_NAME)/bin
	@cp -R $(DIR)/etc/ tmp/$(APP_NAME)/etc
	@cp -R $(DIR)/data/ tmp/$(APP_NAME)/data
	@mkdir -p tmp/$(APP_NAME)/logs
	tar -cf $@ -C tmp $(APP_NAME);
	@rm -rf tmp

# for (Mac OS X 10.8 and above and iOS)
dist-darwin-amd64:
	export GOOS="darwin"; \
	export GOARCH="amd64"; \
	$(MAKE) dist-build

# for linux 64 bit i386
dist-linux-amd64:
	export GOOS="linux"; \
	export GOARCH="amd64"; \
	$(MAKE) dist-build

# for Raspberry PI Zero W
dist-linux-arm:
	export GOOS="linux"; \
	export GOARCH="arm"; \
	$(MAKE) dist-build

# for windows 64 bit i386
dist-windows-amd64:
	export GOOS="windows"; \
	export GOARCH="amd64"; \
	$(MAKE) dist-build

dist-build: $(PACKAGE)

dist: dist-darwin-amd64

dist-all: dist-linux-amd64 dist-linux-arm dist-windows-amd64 dist-darwin-amd64