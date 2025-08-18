# Makefile for TrySpace FSW development
.PHONY: all build clean debug runtime start stop

export BUILDDIR ?= $(CURDIR)/build
export BUILDTYPE ?= debug
export CFS_APP_PATH = ../comp
export COVDIR ?= $(BUILDDIR)/amd64-linux/default_cpu1
export INSTALLPREFIX ?= exe
export MISSION_DEFS ?= ./tryspace_defs
export MISSIONCONFIG ?= ./tryspace
export TOPDIR ?= $(CURDIR)/..

export BUILD_IMAGE ?= tryspaceorg/tryspace-lab:0.0.0
export RUNTIME_FSW_IMAGE_NAME ?= tryspace-fsw

# Determine number of parallel jobs to avoid maxing out low-power systems (Raspberry Pi etc.).
# Use `nproc - 1` but ensure at least 1 job.
NPROC := $(shell nproc 2>/dev/null || echo 1)
JOBS := $(shell if [ $(NPROC) -le 1 ]; then echo 1; else expr $(NPROC) - 1; fi)

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
	docker run --rm -it -v $(TOPDIR):$(TOPDIR) --name "tryspace_fsw_build" -w $(CURDIR) --user $(shell id -u):$(shell id -g) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE) make -j$(JOBS) build-fsw

build-fsw:
	mkdir -p $(BUILDDIR)
	cd $(BUILDDIR) && cmake $(PREP_OPTS) ../cfe
	$(MAKE) --no-print-directory -C $(BUILDDIR) mission-install

build-test:
	mkdir -p $(BUILDDIR)
	cd $(BUILDDIR) && cmake $(PREP_OPTS) -DENABLE_UNIT_TESTS=true ../cfe
	$(MAKE) --no-print-directory -C $(BUILDDIR) mission-install
	cd $(COVDIR) && ctest -O ctest.log
	lcov -c --directory . --output-file $(COVDIR)/coverage.info
	genhtml $(COVDIR)/coverage.info --output-directory $(COVDIR)/report
	@echo ""
	@echo "Review coverage report: "
	@echo "  firefox $(COVDIR)/report/index.html"
	@echo ""

clean:
	rm -rf $(BUILDDIR)

debug:
	docker run --rm -it -v $(TOPDIR):$(TOPDIR) --name "tryspace_fsw_debug" -w $(CURDIR) --user $(shell id -u):$(shell id -g) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE) /bin/bash

runtime:
	$(MAKE) clean build
	docker build -t $(RUNTIME_FSW_IMAGE_NAME) -f tools/Dockerfile.fsw .

start:
	docker run --rm -it --name "tryspace_fsw_runtime" --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(RUNTIME_FSW_IMAGE_NAME)

stop:
	docker ps --filter name=tryspace-* --filter status=running -aq | xargs docker stop
