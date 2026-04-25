project('owl', 'objc', 'c',
  version: '0.1.0',
  license: 'GPL-3.0-or-later',
  default_options: ['warning_level=1'],
)

cc = meson.get_compiler('c')
is_darwin = host_machine.system() == 'darwin'

# --- Dependencies ---

if not cc.has_header('sys/epoll.h')
  epoll_shim_dep = dependency('epoll-shim')
else
  epoll_shim_dep = dependency('', required: false)
endif

wayland_proj = subproject('wayland', default_options: [
  'documentation=false',
  'dtd_validation=false',
  'libraries=true',
  'scanner=true',
])
wayland_server_dep = wayland_proj.get_variable('wayland_server_dep')
wayland_scanner = wayland_proj.get_variable('wayland_scanner')

xkbcommon_dep = dependency('xkbcommon')

deps = [wayland_server_dep, xkbcommon_dep]

if is_darwin
  deps += dependency('appleframeworks', modules: ['Cocoa', 'OpenGL', 'IOSurface'])
  if epoll_shim_dep.found()
    deps += epoll_shim_dep
  endif
else
  deps += dependency('gnustep-gui')
  deps += dependency('gnustep-base')
  deps += cc.find_library('objc')
endif

# --- Wayland protocol generation ---

protocols = [
  'owl-iosurface-unstable-v1',
  'owl-mach-ipc-unstable-v1',
  'wlr-data-control-unstable-v1',
  'xdg-shell-unstable-v6',
  'xdg-shell',
]

protocol_src = []

foreach proto : protocols
  protocol_src += custom_target(proto + '-header',
    command: [wayland_scanner, 'server-header', '@INPUT@', '@OUTPUT@'],
    input: 'Sources/Protocol' / proto + '.xml',
    output: proto + '.h',
  )
  protocol_src += custom_target(proto + '-code',
    command: [wayland_scanner, 'private-code', '@INPUT@', '@OUTPUT@'],
    input: 'Sources/Protocol' / proto + '.xml',
    output: proto + '.c',
  )
endforeach

# --- MIG generation (Darwin only) ---

if is_darwin
  mig = find_program('mig')

  foreach def : ['owl-iosurface-unstable-v1-mig', 'owl-mach-ipc-unstable-v1-mig']
    protocol_src += custom_target(def + '-header',
      command: [mig, '-sheader', '@OUTPUT@', '-server', '/dev/null',
                '-header', '/dev/null', '-user', '/dev/null', '@INPUT@'],
      input: 'Sources/Protocol' / def + '.defs',
      output: def + '.h',
    )
    protocol_src += custom_target(def + '-code',
      command: [mig, '-server', '@OUTPUT@',
                '-header', '/dev/null', '-user', '/dev/null', '@INPUT@'],
      input: 'Sources/Protocol' / def + '.defs',
      output: def + '.c',
    )
  endforeach
endif

# --- Source files ---

src = files(
  'Sources/App/OwlAppDelegate.m',
  'Sources/App/OwlKnownClientsManager.m',
  'Sources/App/OwlPreferences.m',
  'Sources/Compositor/OwlBuffer.m',
  'Sources/Compositor/OwlCompositor.m',
  'Sources/Compositor/OwlIOSurfaceBuffer.m',
  'Sources/Compositor/OwlRegion.m',
  'Sources/Compositor/OwlShmBuffer.m',
  'Sources/Compositor/OwlSubcompositor.m',
  'Sources/Compositor/OwlSubsurface.m',
  'Sources/Compositor/OwlSurface.m',
  'Sources/Compositor/OwlSurfaceState.m',
  'Sources/Compositor/OwlZowlIOSurfaceManagerV1.m',
  'Sources/Compositor/OwlZowlIOSurfaceV1.m',
  'Sources/Data/OwlDataDevice.m',
  'Sources/Data/OwlDataOffer.m',
  'Sources/Data/OwlDataSource.m',
  'Sources/Data/OwlPasteboardDataDevice.m',
  'Sources/Data/OwlPasteboardDataOffer.m',
  'Sources/Data/OwlPasteboardDataSource.m',
  'Sources/Data/OwlPasteboardType.m',
  'Sources/Data/OwlSelection.m',
  'Sources/Data/OwlWlDataDevice.m',
  'Sources/Data/OwlWlDataDeviceManager.m',
  'Sources/Data/OwlWlDataOffer.m',
  'Sources/Data/OwlWlDataSource.m',
  'Sources/Data/OwlZwlrDataControlDeviceV1.m',
  'Sources/Data/OwlZwlrDataControlManagerV1.m',
  'Sources/Data/OwlZwlrDataControlOfferV1.m',
  'Sources/Data/OwlZwlrDataControlSourceV1.m',
  'Sources/Seat/OwlKeyboard.m',
  'Sources/Seat/OwlPointer.m',
  'Sources/Seat/OwlSeat.m',
  'Sources/Server/main.m',
  'Sources/Server/OwlCallback.m',
  'Sources/Server/OwlRunLoopSource.m',
  'Sources/Server/OwlServer.m',
  'Sources/Shell/OwlWindow.m',
  'Sources/Shell/OwlWindowWrapper.m',
  'Sources/Shell/OwlWlShell.m',
  'Sources/Shell/OwlWlShellSurface.m',
  'Sources/Shell/OwlXdgSurface.m',
  'Sources/Shell/OwlXdgToplevel.m',
  'Sources/Shell/OwlXdgWmBase.m',
  'Sources/Shell/OwlZxdgShellV6.m',
  'Sources/Shell/OwlZxdgSurfaceV6.m',
  'Sources/Shell/OwlZxdgToplevelV6.m',
)

if is_darwin
  src += files(
    'Sources/Mach/OwlMIG.m',
    'Sources/Mach/OwlZowlMachIpcPortV1.m',
    'Sources/Mach/OwlZowlMachIpcV1.m',
  )
endif

inc = include_directories(
  'Sources',
  'Sources/App',
  'Sources/Compositor',
  'Sources/Data',
  'Sources/Mach',
  'Sources/Protocol',
  'Sources/Seat',
  'Sources/Server',
  'Sources/Shell',
)

# --- Build executable ---

owl = executable('Owl',
  src,
  protocol_src,
  include_directories: inc,
  dependencies: deps,
  build_rpath: '@loader_path',
)

# --- App bundle ---

if is_darwin
  bundle_dir = meson.current_build_dir() / 'Owl.app' / 'Contents'
  ibtool = find_program('ibtool')
else
  bundle_dir = meson.current_build_dir() / 'Owl.app'
endif

bundle_resources = []

foreach res : ['keymap.xkb', 'Owl.icns']
  bundle_resources += custom_target('bundle-' + res,
    command: ['cp', '@INPUT@', '@OUTPUT@'],
    input: 'Resources' / res,
    output: res,
    build_by_default: true,
  )
endforeach

if is_darwin
  foreach xib : ['MainMenu', 'OwlPreferences']
    bundle_resources += custom_target('bundle-' + xib + '-nib',
      command: [ibtool, '--compile', '@OUTPUT@', '@INPUT@'],
      input: 'Resources/English.lproj' / xib + '.xib',
      output: xib + '.nib',
      build_by_default: true,
    )
  endforeach
endif

bundle_cmd_args = []
if is_darwin
  bundle_cmd_args += [bundle_dir, 'darwin']
else
  bundle_cmd_args += [bundle_dir, 'other']
endif

custom_target('owl-bundle',
  command: [
    'sh', '-c', '''
    bundle_dir="$1"
    platform="$2"
    owl_exe="$3"
    shift 3

    if [ "$platform" = "darwin" ]; then
      exe_dir="$bundle_dir/MacOS"
      res_dir="$bundle_dir/Resources"
    else
      exe_dir="$bundle_dir"
      res_dir="$bundle_dir/Resources"
    fi

    mkdir -p "$exe_dir" "$res_dir/English.lproj"
    cp "$owl_exe" "$exe_dir/Owl"

    # Copy dylibs next to the executable so @loader_path finds them
    build_dir=$(dirname "$owl_exe")
    for dylib in "$build_dir"/subprojects/wayland/src/libwayland-server*.dylib; do
      [ -f "$dylib" ] && cp "$dylib" "$exe_dir/"
    done

    for f in "$@"; do
      base=$(basename "$f")
      case "$base" in
        *.nib) cp -R "$f" "$res_dir/English.lproj/$base" ;;
        *)     cp "$f" "$res_dir/$base" ;;
      esac
    done
    ''',
    'sh',
    bundle_dir,
    is_darwin ? 'darwin' : 'other',
    owl,
  ] + bundle_resources,
  output: 'Owl.app',
  depends: [owl] + bundle_resources,
  build_by_default: true,
)

# Copy plist separately (different source per platform)
if is_darwin
  plist_input = 'Resources/Owl-Info.plist'
  plist_dest = bundle_dir / 'Info.plist'
else
  plist_input = 'Resources/Owl-Info-gnustep.plist'
  plist_dest = bundle_dir / 'Resources' / 'Info-gnustep.plist'
endif

custom_target('bundle-plist',
  command: ['sh', '-c', 'mkdir -p "$(dirname "$2")" && cp "$1" "$2"', 'sh', '@INPUT@', plist_dest],
  input: plist_input,
  output: 'bundle-plist.stamp',
  build_by_default: true,
)
