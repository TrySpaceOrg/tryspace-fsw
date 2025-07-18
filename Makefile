# Makefile for TrySpace FSW development environment
.PHONY: all build debug run clean container runtime

export BUILDDIR ?= $(CURDIR)/build
export BUILDTYPE ?= debug
export CFS_APP_PATH = ../components
export INSTALLPREFIX ?= exe
export MISSION_DEFS = ./tryspace_defs
export MISSIONCONFIG = ./tryspace

export BUILD_IMAGE_NAME ?= tryspace-fsw
export RUNTIME_IMAGE_NAME ?= tryspace-fsw-runtime

# The "prep" step requires extra options that are specified via environment variables
PREP_OPTS :=
ifneq ($(INSTALLPREFIX),)
PREP_OPTS += -DCMAKE_INSTALL_PREFIX=$(INSTALLPREFIX)
endif
ifneq ($(VERBOSE),)
PREP_OPTS += --trace
endif
ifneq ($(BUILDTYPE),)
PREP_OPTS += -DCMAKE_BUILD_TYPE=$(BUILDTYPE)
endif

# Commands
all: build

build:
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_fsw_build" -w $(CURDIR) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE_NAME) make -j build-fsw

build-fsw:
	mkdir -p $(BUILDDIR)
	cd $(BUILDDIR) && cmake $(PREP_OPTS) ../cfe
	$(MAKE) --no-print-directory -C $(BUILDDIR) mission-install

debug:
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_fsw_debug" -w $(CURDIR) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE_NAME) /bin/bash

clean:
	rm -rf $(BUILDDIR)

container:
	docker build -t $(BUILD_IMAGE_NAME) -f docker/Dockerfile.build -t tryspace-fsw .

runtime:
	$(MAKE) clean container build
	docker build -t $(RUNTIME_IMAGE_NAME) -f docker/Dockerfile.runtime -t tryspace-fsw-runtime .

start:
	docker run --rm -it --name "tryspace_fsw_runtime" --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(RUNTIME_IMAGE_NAME) ./core-cpu1
