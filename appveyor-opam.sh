#!/usr/bin/env sh

export OPAMYES=1

curl -fsSL -o opam64.tar.xz "https://dl.dropboxusercontent.com/s/b2q2vjau7if1c1b/opam64.tar.xz"
tar -xf opam64.tar.xz
opam64/install.sh
opam init -a mingw "https://github.com/fdopen/opam-repository-mingw.git" --comp 4.02.3+mingw64c --switch 4.02.3+mingw64c
opam install depext-cygwinports depext

opam pin add my-pkg "${APPVEYOR_BUILD_FOLDER}" -n -k path
opam depext  my-pkg
opam install my-pkg
