#!/bin/bash
set -ex

SCRIPT=".travis-docker.sh"
wget https://raw.githubusercontent.com/ocaml/ocaml-travisci-skeleton/master/${SCRIPT} -O /build-script/${SCRIPT}

. /build-script/env.sh

cp -ar /root/build/orig/. /root/build/repo
cd /root/build/repo || exit
git ls-files . --others | xargs rm -rf

TRAVIS_OS_NAME=linux \
    TRAVIS_REPO_SLUG=repo \
    bash -ex /build-script/${SCRIPT}
