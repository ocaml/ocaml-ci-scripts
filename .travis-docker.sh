#!/bin/sh -e
# To use this, run `opam travis --help`

echo -en "travis_fold:start:prepare.ci\r"
default_user=ocaml
default_branch=master
default_hub_user=ocaml

fork_user=${FORK_USER:-$default_user}
fork_branch=${FORK_BRANCH:-$default_branch}
hub_user=${HUB_USER:-$default_hub_user}

# create env file
echo PACKAGE="$PACKAGE" > env.list
echo EXTRA_REMOTES="$EXTRA_REMOTES" >> env.list
echo PINS="$PINS" >> env.list
echo INSTALL="$INSTALL" >> env.list
echo DEPOPTS="$DEPOPTS" >> env.list
echo TESTS="$TESTS" >> env.list
echo REVDEPS="$REVDEPS" >> env.list
echo EXTRA_DEPS="$EXTRA_DEPS" >> env.list
echo PRE_INSTALL_HOOK="$PRE_INSTALL_HOOK" >> env.list
echo POST_INSTALL_HOOK="$POST_INSTALL_HOOK" >> env.list
echo $EXTRA_ENV >> env.list

# build a local image to trigger any ONBUILDs
echo FROM ${hub_user}/opam:${DISTRO}_ocaml-${OCAML_VERSION} > Dockerfile
echo WORKDIR /home/opam/opam-repository >> Dockerfile

if [ -n "$BASE_REMOTE" ]; then
    echo "RUN git remote set-url origin ${BASE_REMOTE} &&\
        git fetch origin && git reset --hard origin/master"  >> Dockerfile
else
    echo RUN git pull origin master >> Dockerfile
fi


echo RUN opam remove travis-opam >> Dockerfile
if [ $fork_user != $default_user -o $fork_branch != $default_branch ]; then
    echo RUN opam pin add -n travis-opam \
         https://github.com/$fork_user/ocaml-ci-scripts.git#$fork_branch \
         >> Dockerfile
fi

echo RUN opam update -u -y >> Dockerfile
echo RUN opam depext -ui travis-opam >> Dockerfile
echo RUN cp '~/.opam/$(opam switch show)/bin/ci-opam' "~/" >> Dockerfile
echo RUN opam remove -a travis-opam >> Dockerfile
echo RUN mv "~/ci-opam" '~/.opam/$(opam switch show)/bin/ci-opam' >> Dockerfile
echo VOLUME /repo >> Dockerfile
echo WORKDIR /repo >> Dockerfile
docker build -t local-build .

echo Dockerfile:
cat Dockerfile
echo env.list:
cat env.list
echo Command:
OS=~/build/$TRAVIS_REPO_SLUG
echo docker run --env-file=env.list -v ${OS}:/repo local-build ci-opam

# run ci-opam with the local repo volume mounted
chmod -R a+w $OS
echo -en "travis_fold:end:prepare.ci\r"
docker run --env-file=env.list -v ${OS}:/repo local-build ci-opam
