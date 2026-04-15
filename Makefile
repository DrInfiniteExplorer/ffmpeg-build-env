

DOCKER = docker compose run --rm $(if $1,$1,-T) ffmpeg-build

# Shell preamble: paths inside the ffmpeg-build docker container.
define FFMPEG_CONFIGURED_TREE_SH_DOCKER=
set -euo pipefail; \
export PKG_CONFIG_DIR=; \
export PKG_CONFIG_PATH=; \
export PKG_CONFIG_LIBDIR=$1/ffmpeg_build/lib/pkgconfig:$1/ffmpeg_build/share/pkgconfig; \
cd $1/src/ffmpeg; \
test -f ffbuild/config.mak -o -f config.mak || { echo 'ffmpeg is not configured yet. Run make rebuild once first.'; exit 1; };
endef

define RewriteHints=
$(eval
$1: $2 $(firstword $(MAKEFILE_LIST))
	sed -E 's|^#([a-z0-9-]+\turl\t)|\1|' $2 | sed 's|file://~/src/|file://$3/|g' > $1
)
endef

yolo:
	echo read the makefile you dofus

shell:
	$(call DOCKER, -it) bash


$(call RewriteHints,my-hints/mingw64,ffmpeg-cxc-build/ffmpeg-cxc-build-hints,/src)

fetch:
	$(DOCKER) bash -lc "ROOT_PATH=/src SRC_PATH=src HINTS_FILE=/dev/null CXC_FETCH_ONLY=1 /build/ffmpeg-cxc-mingw64"

rebuild:
	$(DOCKER) bash -lc "ROOT_PATH=/output SRC_PATH=src HINTS_FILE=/my-hints/mingw64 CXC_SHOW_ONLY=0 /build/ffmpeg-cxc-mingw64"


$(call RewriteHints,my-hints/native,ffmpeg-cxc-build/ffmpeg-native-build-hints,/src-native/src)

fetch-native:
	chmod +x ffmpeg-cxc-build/ffmpeg-native
	$(DOCKER) bash -lc "ROOT_PATH=/src-native SRC_PATH=src HINTS_FILE=/dev/null NCC_FETCH_ONLY=1 /build/ffmpeg-native"

rebuild-native:	my-hints/native
	$(DOCKER) bash -lc "ROOT_PATH=/native SRC_PATH=src HINTS_FILE=/my-hints/native NCC_SHOW_ONLY=0 /build/ffmpeg-native"


ffmpeg:
	$(DOCKER) bash -lc "$(call FFMPEG_CONFIGURED_TREE_SH_DOCKER,/output) make -j\$$(getconf _NPROCESSORS_ONLN); make install"

# Full FATE suite inside Docker. Optional: make test SAMPLES=/path/to/fate-suite
test:
	$(DOCKER) bash -lc "$(call FFMPEG_CONFIGURED_TREE_SH_DOCKER,/native) make fate -j1 $(if $(SAMPLES),SAMPLES=$(SAMPLES),)"

# Requires ffprobe runnable on the host that runs fate-run.sh (native ELF on
# Linux). A MinGW-only tree produces ffprobe.exe and these tests fail with 127.
test-response-file:
	$(DOCKER) bash -lc "$(call FFMPEG_CONFIGURED_TREE_SH_DOCKER,/native) make fate-response-file -j\$$(getconf _NPROCESSORS_ONLN)"


.PHONY: yolo shell fetch rebuild ffmpeg test test-response-file
