# Appveyor CI scripts

Instructions:

1. Create an `opam` file at the root of your project. If you use opam
   1.2, you can simply do `opam pin add PKG .` -- this will open an
   editor and propose you a template.

2. Copy [appveyor.yml](https://raw.githubusercontent.com/ocaml/ocaml-ci-scripts/master/appveyor.yml)
   at the root of your project.

3. Enable Appveyor runs on
   https://ci.appveyor.com/projects (sign in with your
   Github account and click on `+` on the top pane).

And that's it!

## Options

Most of the options detailed in [TravisCI scripts](/README-travis.md)
are valid.

### OPAM_SWITCH

`OCAML_VERSION` is however handled differently. There are currently
three
[Windows ports of OCaml](https://github.com/ocaml/ocaml/blob/trunk/README.win32.adoc):

- Native Microsoft (msvc)
- Native Mingw-w64
- Cygwin

Each variant is available in a 32-bit and 64-bit version.

The native mingw-w64 port is supported through cygwin's
[mingw-w64 cross compiler](http://mingw-w64.org/doku.php/download/cygwin),
the msvc version through
[Visual Studio Community 2015](https://www.appveyor.com/docs/installed-software/#visual-studio-2015).
The cygwin port is currently not supported by these scripts.

You can choose between different ports and versions through the
`OPAM_SWITCH` variable, e.g:

```yaml
environment:
  matrix:
    - OPAM_SWITCH: 4.04.0+msvc32
    - OPAM_SWITCH: 4.03.0+mingw64c
    # syntax: ${OCAML_VERSION}+${PORT}${WORD_SIZE}c?
```

Some versions are available as pre-compiled binaries to speed up the
build process (the 'c'-suffix), but not all.

If you don't specify `OPAM_SWITCH` manually, a recent, pre-compiled
mingw port (64-bit) is used. The build instructions of many opam
packages are only compatible with gcc.

### Other environment variables

#### CYG_ROOT

Cygwin is used by `ocaml-ci-scripts` and nearly all opam packages
depend on it.  By default, the 64-bit version is used. You can switch
to the 32-bit version by setting `CYG_ROOT` to `C:\cygwin`.

#### CYG_MIRROR

Cygwin must be updated during the install step. The mirror for this
task must be specified manually. If the mirror that is normally used
goes offline or becomes too slow, you can point `CYG_MIRROR` to
another [supported mirror](https://cygwin.com/mirrors.lst).

#### CYG_PKGS

If you need additional packages from cygwin, you can add them to
`CYG_PKGS` (comma separated). By default, the `mingw64-x86_64`
toolchain is updated. But for most use cases, you should rely on
[depext-cygwinports](https://fdopen.github.io/opam-repository-mingw/depext-cygwin/).
