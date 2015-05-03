## mirage setup

set -ex

# If a fork of these scripts are specified, use that GitHub user instead
fork_user=${FORK_USER:-ocaml}

## fetch+execute the OCaml/opam setup script
wget https://raw.githubusercontent.com/${fork_user}/ocaml-travisci-skeleton/master/.travis-ocaml.sh
sh .travis-ocaml.sh

## install mirage
export OPAMYES=1
eval $(opam config env)
opam install mirage

DEPLOY=$DEPLOY MODE=$MIRAGE_BACKEND NET=$MIRAGE_NET \
      ADDR=$MIRAGE_ADDR MASK=$MIRAGE_MASK GWS=$MIRAGE_GWS \
      make configure
make build

## stash deployment build if specified
if [ "$DEPLOY" = "1" \
               -a "$TRAVIS_PULL_REQUEST" = "false" \
               -a -n "$XSECRET_default_0" ]; then
    opam install travis-senv
    # get the secure key out for deployment
    mkdir -p ~/.ssh
    SSH_DEPLOY_KEY=~/.ssh/id_dsa
    travis-senv decrypt > $SSH_DEPLOY_KEY
    chmod 600 $SSH_DEPLOY_KEY

    echo "Host mir-deploy github.com"      >> ~/.ssh/config
    echo "   Hostname github.com"          >> ~/.ssh/config
    echo "   StrictHostKeyChecking no"     >> ~/.ssh/config
    echo "   CheckHostIP no"               >> ~/.ssh/config
    echo "   UserKnownHostsFile=/dev/null" >> ~/.ssh/config

    git config --global user.email "travis@openmirage.org"
    git config --global user.name "Travis the Build Bot"
    git clone git@mir-deploy:${TRAVIS_REPO_SLUG}-deployment

    DEPLOYD=${TRAVIS_REPO_SLUG#*/}-deployment
    XENIMG=mir-${XENIMG:-$TRAVIS_REPO_SLUG#mirage/mirage-}.xen
    case "$MIRAGE_BACKEND" in
        xen)
            cd $DEPLOYD
            rm -rf xen/$TRAVIS_COMMIT
            mkdir -p xen/$TRAVIS_COMMIT
            cp ../src/$XENIMG ../src/config.ml xen/$TRAVIS_COMMIT
            bzip2 -9 xen/$TRAVIS_COMMIT/$XENIMG
            echo $TRAVIS_COMMIT > xen/latest
            git add xen/$TRAVIS_COMMIT xen/latest
            ;;
        *)
            echo unsupported deploy mode: $MIRAGE_BACKEND
            exit 1
            ;;
    esac
    git commit -m "adding $TRAVIS_COMMIT for $MIRAGE_BACKEND"
    git push
fi
