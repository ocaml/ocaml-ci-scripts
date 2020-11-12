#!/bin/sh -e
# To use this, run `opam travis --help`

fold_name="prepare"
( set +x; echo -en "travis_fold:start:$fold_name.ci\r" ) 2>/dev/null
default_user=ocaml
default_branch=master
default_hub_user=ocaml
default_opam_version=2
default_base_remote_branch=master
beta_repository=git://github.com/ocaml/ocaml-beta-repository.git

fork_user=${FORK_USER:-$default_user}
fork_branch=${FORK_BRANCH:-$default_branch}
hub_user=${HUB_USER:-$default_hub_user}
opam_version=${OPAM_VERSION:-$default_opam_version}
base_remote_branch=${BASE_REMOTE_BRANCH:-$default_base_remote_branch}

if [ "$OCAML_BETA" = "enable" ]; then
    EXTRA_REMOTES="${EXTRA_REMOTES}${EXTRA_REMOTES:+ }$beta_repository"
fi

# create env file
rm -f env.list
if [ -n "${PACKAGE+x}" ] ; then echo PACKAGE="$PACKAGE" >> env.list ; fi
if [ -n "${EXTRA_REMOTES+x}" ] ; then echo EXTRA_REMOTES="$EXTRA_REMOTES" >> env.list ; fi
if [ -n "${PINS+x}" ] ; then echo PINS="$PINS" >> env.list ; fi
if [ -n "${INSTALL+x}" ] ; then echo INSTALL="$INSTALL" >> env.list ; fi
if [ -n "${DEPOPTS+x}" ] ; then echo DEPOPTS="$DEPOPTS" >> env.list ; fi
if [ -n "${TESTS+x}" ] ; then echo TESTS="$TESTS" >> env.list ; fi
if [ -n "${REVDEPS+x}" ] ; then echo REVDEPS="$REVDEPS" >> env.list ; fi
if [ -n "${EXTRA_DEPS+x}" ] ; then echo EXTRA_DEPS="$EXTRA_DEPS" >> env.list ; fi
if [ -n "${PRE_INSTALL_HOOK+x}" ] ; then echo PRE_INSTALL_HOOK="$PRE_INSTALL_HOOK" >> env.list ; fi
if [ -n "${POST_INSTALL_HOOK+x}" ] ; then echo POST_INSTALL_HOOK="$POST_INSTALL_HOOK" >> env.list ; fi
echo $EXTRA_ENV >> env.list

if [ "$opam_version" != "2" ] ; then
  set +x
  # There is no way to tell Travis to close a fold but have it initially
  # open.
  echo -en "travis_fold:end:$fold_name.ci\r"
  echo -e "[\e[0;31mWARNING\e[0m] Ignored OPAM_VERSION=$OPAM_VERSION; interpreted as \"2\"" >&2
  echo -e "[\e[0;31mWARNING\e[0m] The containers have the latest maintenance release of opam 2.0" >&2
  opam_version=2
  echo -en "travis_fold:start:continue.ci\r"
  fold_name="continue"
  set -x
fi
from=${hub_user}/opam:${DISTRO}

echo FROM $from  > Dockerfile
echo WORKDIR /home/opam/opam-repository >> Dockerfile

if [ -n "$BASE_REMOTE" ]; then
    echo "RUN opam repo remove --all default && opam repo add --all-switches default ${BASE_REMOTE}#${base_remote_branch}" >> Dockerfile
else
    echo RUN git checkout master >> Dockerfile
    echo RUN git pull -q origin master >> Dockerfile
fi
echo RUN opam update --verbose >> Dockerfile

echo RUN opam remove travis-opam >> Dockerfile
if [ $fork_user != $default_user -o $fork_branch != $default_branch ]; then
    echo RUN opam pin add -n travis-opam \
         https://github.com/$fork_user/ocaml-ci-scripts.git#$fork_branch \
         >> Dockerfile
fi

opam_repo_selection=
ocaml_package=ocaml-base-compiler
if [ "$OCAML_BETA" = "enable" ]; then
    echo "RUN opam repo add --dont-select beta $beta_repository" >> Dockerfile
    opam_repo_selection="--repo=default,beta "
    ocaml_package=ocaml-variants
fi
echo "RUN opam switch ${OCAML_VERSION} ||\
    opam switch create ${opam_repo_selection}${ocaml_package}.${OCAML_VERSION}" >> Dockerfile

echo RUN opam upgrade -y >> Dockerfile
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
( set +x; echo -en "travis_fold:end:$fold_name.ci\r" ) 2>/dev/null
docker run --env-file=env.list -v ${OS}:/repo local-build ci-opam
