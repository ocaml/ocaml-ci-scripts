#!/usr/bin/env sh

# default setttings
SWITCH='4.02.3+mingw64c'
OPAM_URL='https://dl.dropboxusercontent.com/s/b2q2vjau7if1c1b/opam64.tar.xz'
OPAM_ARCH=opam64

if [ "$PROCESSOR_ARCHITECTURE" != "AMD64" ] && \
       [ "$PROCESSOR_ARCHITEW6432" != "AMD64" ]; then
    OPAM_URL='https://dl.dropboxusercontent.com/s/eo4igttab8ipyle/opam32.tar.xz'
    OPAM_ARCH=opam32
fi

if [ $# -gt 0 ] && [ -n "$1" ]; then
    SWITCH=$1
fi

export CYGWIN='winsymlinks:native'
export OPAMYES=1

set -eu

curl -fsSL -o "${OPAM_ARCH}.tar.xz" "${OPAM_URL}"
tar -xf "${OPAM_ARCH}.tar.xz"
"${OPAM_ARCH}/install.sh"

opam init -a mingw "https://github.com/fdopen/opam-repository-mingw.git" --comp "$SWITCH" --switch "$SWITCH"
eval $(opam config env)
ocaml_system="$(ocamlc -config | awk '/^system:/ { print $2 }')"
case "$ocaml_system" in
    *mingw64*)
        PATH="/usr/x86_64-w64-mingw32/sys-root/mingw/bin:${PATH}"
        export PATH
        ;;
    *mingw*)
        PATH="/usr/i686-w64-mingw32/sys-root/mingw/bin:${PATH}"
        export PATH
        ;;
    *)
        echo "ocamlc reports a dubious system: ${ocaml_system}. Good luck!" >&2
esac
opam install depext-cygwinports depext
eval $(opam config env)
opam pin add my-pkg "${APPVEYOR_BUILD_FOLDER}" -n -k path
opam depext  my-pkg
opam install my-pkg
