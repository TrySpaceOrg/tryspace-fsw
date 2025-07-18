# Makefile for TrySpace FSW Docker development environment
.PHONY: all build debug run clean

BUILDDIR ?= $(CURDIR)/build
IMAGE_NAME := tryspace-fsw

export CFS_APP_PATH = ../components
export MISSION_DEFS = ./tryspace_defs
export MISSIONCONFIG = ./tryspace

all: build

build:
	docker run --rm -it -v $(CURDIR):/opt/fsw --name "tryspace_fsw_debug" -w /opt/fsw $(IMAGE_NAME) make -j build-fsw

build-fsw:
	mkdir -p $(BUILDDIR)
	cd $(BUILDDIR) && cmake ../cfe
	$(MAKE) --no-print-directory -C $(BUILDDIR) mission-install

debug:
	docker run --rm -it -v $(CURDIR):/opt/fsw --name "tryspace_fsw_debug" -w /opt/fsw $(IMAGE_NAME) /bin/bash

clean:
	rm -rf $(BUILDDIR)
