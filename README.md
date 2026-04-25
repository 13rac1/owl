# Owl

Owl is a portable [Wayland] compositor written in Objective-C, using Cocoa as
its backend. Owl primarily targets macOS, but also supports other operating
systems via [GNUstep].

[Wayland]: https://wayland.freedesktop.org/
[GNUstep]: http://www.gnustep.org/

Owl makes it possible to run Wayland clients inside macOS's native Quartz
graphics environment, similar to [XQuartz] for X11.

[XQuartz]: https://www.xquartz.org/

## Status

This is a fork with a fixed build system (meson, replacing the old `configure`
script). The original project is unmaintained.

## Building

Prerequisites:

```
brew install cmake meson libxkbcommon
```

Build:

```
make
```

If the build succeeds, you'll find `Owl.app` in `build/Owl.app/`.

Other targets:

```
make help       # list all targets
make deps       # build epoll-shim only
make build      # build Owl only (after deps)
make clean      # clean Owl build
make clean-all  # clean everything
```

## License

Owl is free software, available under the GNU General Public License version 3
or later.
