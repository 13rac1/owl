.POSIX:
.PHONY: all help deps build clean clean-deps clean-all

PREFIX = $(CURDIR)/deps/install

all: build

help:
	@echo "Targets:"
	@echo "  make         - Build everything (deps + owl)"
	@echo "  make deps    - Build epoll-shim (cmake)"
	@echo "  make build   - Configure and build Owl (meson)"
	@echo "  make clean   - Clean Owl build"
	@echo "  make clean-deps - Clean epoll-shim build"
	@echo "  make clean-all  - Clean everything"
	@echo ""
	@echo "Prerequisites: brew install cmake meson libxkbcommon"

# --- epoll-shim (cmake, pre-built so wayland finds it via pkg-config) ---

deps: deps/.stamp

deps/.stamp: subprojects/epoll-shim/CMakeLists.txt
	cmake -S subprojects/epoll-shim -B subprojects/epoll-shim/build \
		-DCMAKE_INSTALL_PREFIX=$(PREFIX)
	cmake --build subprojects/epoll-shim/build --target install
	@touch $@

subprojects/epoll-shim/CMakeLists.txt:
	git clone --depth 1 --branch v0.0.20240608 \
		https://github.com/jiixyj/epoll-shim.git subprojects/epoll-shim

# --- owl (meson, with wayland as subproject) ---

build: deps
	@if [ ! -f build/build.ninja ]; then \
		PKG_CONFIG_PATH=$(PREFIX)/libdata/pkgconfig:$(PREFIX)/lib/pkgconfig \
			meson setup build; \
	fi
	meson compile -C build

# --- clean ---

clean:
	rm -rf build

clean-deps:
	rm -rf subprojects/epoll-shim/build deps
	rm -f deps/.stamp

clean-all: clean clean-deps
	rm -rf subprojects/epoll-shim subprojects/wayland subprojects/packagecache
