#!/usr/bin/env sh

APPVEYOR_YML_VERSION=0

# If a fork of these scripts is specified, use that GitHub user instead
fork_user=${FORK_USER:-ocaml}

# If a branch of these scripts is specified, use that branch instead of 'master'
fork_branch=${FORK_BRANCH:-master}

# default setttings
OPAM_VERSION=${OPAM_VERSION:-2.0.0}
case "$OPAM_VERSION" in
    1*)
        SWITCH=${OPAM_SWITCH:-'4.03.0+mingw64c'}
        OPAM_DL_SUB_LINK=0.0.0.1
        ;;
    *)
        SWITCH=${OPAM_SWITCH:-'4.07.1+mingw64c'}
        OPAM_DL_SUB_LINK=0.0.0.2
        ;;
esac

OPAM_URL="https://github.com/fdopen/opam-repository-mingw/releases/download/${OPAM_DL_SUB_LINK}/opam64.tar.xz"
OPAM_ARCH=opam64
if [ "$PROCESSOR_ARCHITECTURE" != "AMD64" ] && \
       [ "$PROCESSOR_ARCHITEW6432" != "AMD64" ]; then
    OPAM_URL="https://github.com/fdopen/opam-repository-mingw/releases/download/${OPAM_DL_SUB_LINK}/opam32.tar.xz"
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

jobs=
jobs_param=
if [ "$APPVEYOR_YML_VERSION" != "0" ]; then
    # The default PATH contains far too many folders. There is always
    # a risk, that a tool is picked from the wrong location. It
    # happend in the past with unzip. It also slows down cygwin.
    PATH=/usr/local/bin:/usr/bin:/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/Wbem:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0
    export PATH
    set +eu
    # see https://www.appveyor.com/docs/build-configuration/#build-environment
    # currently NUMBER_OF_PROCESSORS matches these settings
    if echo "$NUMBER_OF_PROCESSORS" | egrep -q '^[0-9]+$' ; then
        if [ $NUMBER_OF_PROCESSORS -gt 1 ]; then
            jobs="$NUMBER_OF_PROCESSORS"
            jobs_param="-j $jobs"
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

case "$OPAM_VERSION" in
    1*)
        opam init $jobs_param -a default "https://github.com/fdopen/opam-repository-mingw.git#opam1" --comp "$SWITCH" --switch "$SWITCH"
        ;;
    *)
        opam init $jobs_param -c "ocaml-variants.${SWITCH}" --disable-sandboxing --enable-completion --enable-shell-hook --auto-setup default "https://github.com/fdopen/opam-repository-mingw.git#opam2"
        ;;
esac

if [ -n "$jobs" ]; then
    opam config set jobs "$jobs"
fi

# update cached .opam
opam update

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
    opam install depext-cygwinports depext
else
    opam install depext
fi

export OPAMYES=1
eval $(opam config env)

echo opam pin add travis-opam https://github.com/${fork_user}/ocaml-ci-scripts.git#${fork_branch}
opam pin add travis-opam https://github.com/${fork_user}/ocaml-ci-scripts.git#${fork_branch}

cd "${APPVEYOR_BUILD_FOLDER}"

# copy the binaries to allow removal of the travis-opam package
opam config exec -- cp $(which ci-opam.exe) ci-opam.exe
opam remove -a travis-opam
"${APPVEYOR_BUILD_FOLDER}"/ci-opam.exe
