#!/usr/bin/env sh

APPVEYOR_YML_VERSION=0

# If a fork of these scripts is specified, use that GitHub user instead
fork_user=${FORK_USER:-ocaml}

# If a branch of these scripts is specified, use that branch instead of 'master'
fork_branch=${FORK_BRANCH:-master}

# default setttings
SWITCH=${OPAM_SWITCH:-'4.03.0+mingw64c'}
OPAM_URL='https://github.com/fdopen/opam-repository-mingw/releases/download/0.0.0.1/opam64.tar.xz'
OPAM_ARCH=opam64

if [ "$PROCESSOR_ARCHITECTURE" != "AMD64" ] && \
       [ "$PROCESSOR_ARCHITEW6432" != "AMD64" ]; then
    OPAM_URL='https://github.com/fdopen/opam-repository-mingw/releases/download/0.0.0.1/opam32.tar.xz'
    OPAM_ARCH=opam32
fi

if [ $# -gt 0 ] && [ -n "$1" ]; then
    SWITCH=$1
fi

export OPAM_LINT="false"
export CYGWIN='winsymlinks:native'
export OPAMYES=1

get() {
  wget --quiet https://raw.githubusercontent.com/${fork_user}/ocaml-ci-scripts/${fork_branch}/$@
}

set -eu

curl -fsSL -o "${OPAM_ARCH}.tar.xz" "${OPAM_URL}"
tar -xf "${OPAM_ARCH}.tar.xz"
"${OPAM_ARCH}/install.sh" --quiet

if [ "$APPVEYOR_YML_VERSION" != "0" ]; then
    # The default PATH contains far too many folders. There is always
    # a risk, that a tool is picked from the wrong location. It
    # happend in the past with unzip. It also slows down cygwin.
    PATH=/usr/local/bin:/usr/bin:/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/Wbem:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0
    export PATH
    set +eu
    # see https://www.appveyor.com/docs/build-configuration/#build-environment
    # currently NUMBER_OF_PROCESSORS matches these settings
    if [ -z "$OPAMJOBS" ]; then
        if echo "$NUMBER_OF_PROCESSORS" | egrep -q '^[0-9]+$' ; then
            if [ $NUMBER_OF_PROCESSORS -gt 1 ]; then
                export OPAMJOBS=$NUMBER_OF_PROCESSORS
            fi
        fi
    fi
    set -eu
fi

# if a msvc compiler must be compiled from source, we have to modify the
# environment first
case "$SWITCH" in
    *msvc32)
        eval $(ocaml-env cygwin --ms=vs2015 --no-opam --32)
        ;;
    *msvc64)
        eval $(ocaml-env cygwin --ms=vs2015 --no-opam --64)
        ;;
esac

opam init -a default "https://github.com/fdopen/opam-repository-mingw.git" --comp "$SWITCH" --switch "$SWITCH"
is_msvc=0
case "$SWITCH" in
    *msvc*)
        is_msvc=1
        eval $(ocaml-env cygwin --ms=vs2015)
        ;;
    *mingw*)
        eval $(ocaml-env cygwin)
        ;;
    *)
        echo "ocamlc reports a dubious system: ${ocaml_system}. Good luck!" >&2
        eval $(opam config env)
esac
if [ $is_msvc -eq 0 ]; then
    opam install depext-cygwinports depext ocamlfind
else
    opam install depext ocamlfind
fi

TMP_BUILD=$(mktemp -d 2>/dev/null || mktemp -d -t 'citmpdir')
cd "${TMP_BUILD}"

echo "downloading ocaml-ci-scripts from github.com/${fork_user}/ocaml-ci-scripts/${fork_branch}" >&2
get ci_opam.ml
get yorick.mli
get yorick.ml

ocamlc.opt yorick.mli
ocamlfind ocamlc -c yorick.ml
ocamlfind ocamlc -o ci-opam.exe -package unix -linkpkg yorick.cmo ci_opam.ml

cd "${APPVEYOR_BUILD_FOLDER}"

${TMP_BUILD}/ci-opam.exe
