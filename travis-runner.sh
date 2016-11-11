#!/bin/bash

cd /build || exit
wget https://raw.githubusercontent.com/ocaml/ocaml-travisci-skeleton/master/.travis-opam.sh
trap 'rm .travis-opam.sh' EXIT

su -l -c "cd /build && \
    TRAVIS_OS_NAME=linux \
    OCAML_VERSION=$OCAML_VERSION \
    PACKAGE=$PACKAGE \
    EXTRA_REMOTES=$EXTRA_REMOTES \
    bash -ex .travis-opam.sh" travis
