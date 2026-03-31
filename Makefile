

DOCKER = docker compose run --rm $(if $1,$1,-T) ffmpeg-build

# Host-local paths for test-local targets. Defaults are relative to the directory
# of this Makefile (GNU Make). Override if your layout differs.
REPO_ROOT := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
FFMPEG_TREE ?= $(REPO_ROOT)/output/src/ffmpeg
FFMPEG_BUILD ?= $(REPO_ROOT)/output/ffmpeg_build
FFMPEG_PKGCONFIG_LIBDIR ?= $(FFMPEG_BUILD)/lib/pkgconfig:$(FFMPEG_BUILD)/share/pkgconfig

# Shell preamble: paths inside the ffmpeg-build docker container.
define FFMPEG_CONFIGURED_TREE_SH_DOCKER
set -euo pipefail; \
export PKG_CONFIG_DIR=; \
export PKG_CONFIG_PATH=; \
export PKG_CONFIG_LIBDIR=/output/ffmpeg_build/lib/pkgconfig:/output/ffmpeg_build/share/pkgconfig; \
cd /output/src/ffmpeg; \
test -f ffbuild/config.mak -o -f config.mak || { echo 'ffmpeg is not configured yet. Run make rebuild once first.'; exit 1; };
endef

define RewriteHints=
$(eval
$1: $2
	sed -E 's|^#([a-z0-9-]+\turl\t)|\1|' $2 | sed 's|file://~/src/|file:///src/src/|g' > $1
)
endef

yolo:
	echo read the makefile you dofus

shell:
	$(call DOCKER, -it) bash


$(call RewriteHints,my-hints/mingw64,ffmpeg-cxc-build/ffmpeg-cxc-build-hints)

fetch:
	$(DOCKER) ROOT_PATH=/src SRC_PATH=src HINTS_FILE=/dev/null CXC_FETCH_ONLY=1 /build/ffmpeg-cxc-mingw64

rebuild:
	$(DOCKER) bash -lc "ROOT_PATH=/output SRC_PATH=src HINTS_FILE=/my-hints/mingw64 CXC_SHOW_ONLY=0 /build/ffmpeg-cxc-mingw64"


$(call RewriteHints,my-hints/native-hints,ffmpeg-cxc-build/ffmpeg-native-build-hints)

fetch-native:
	$(DOCKER) ROOT_PATH=/src-native SRC_PATH=src HINTS_FILE=/dev/null CXC_FETCH_ONLY=1 /build/ffmpeg-native

rebuild-native:	my-hints/native-hints
	$(DOCKER) bash -lc "ROOT_PATH=/native SRC_PATH=src HINTS_FILE=/my-hints/native CXC_SHOW_ONLY=0 /build/ffmpeg-native"


ffmpeg:
	$(DOCKER) bash -lc "$(FFMPEG_CONFIGURED_TREE_SH_DOCKER) make -j\$$(getconf _NPROCESSORS_ONLN); make install"

# Full FATE suite inside Docker. Optional: make test SAMPLES=/path/to/fate-suite
test:
	$(DOCKER) bash -lc "$(FFMPEG_CONFIGURED_TREE_SH_DOCKER) make fate -j\$$(getconf _NPROCESSORS_ONLN) $(if $(SAMPLES),SAMPLES=$(SAMPLES),)"

# Requires ffprobe runnable on the host that runs fate-run.sh (native ELF on
# Linux). A MinGW-only tree produces ffprobe.exe and these tests fail with 127.
test-response-file:
	$(DOCKER) bash -lc "$(FFMPEG_CONFIGURED_TREE_SH_DOCKER) make fate-response-file -j\$$(getconf _NPROCESSORS_ONLN)"


.PHONY: yolo shell fetch rebuild ffmpeg test test-response-file
