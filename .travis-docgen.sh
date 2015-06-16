#!/bin/sh
set -e
# Make sure we're not echoing any sensitive data
set +x

eval `opam config env`
./configure --enable-docs
make doc

if [ -z "$TRAVIS" -o "$TRAVIS_PULL_REQUEST" != "false" ]; then
  echo "This is not a push Travis-ci build, doing nothing..."
  exit 0
else
  echo "Updating docs on Github pages..."
fi

DOCDIR=.gh-pages
if [ -n "$KEEP" ]; then trap "rm -rf $DOCDIR" EXIT; fi
rm -rf $DOCDIR

# Error out if $GH_TOKEN is empty or unset
: ${GH_TOKEN:?"GH_TOKEN need to be uploaded via travis-encrypt"}

git clone --quiet https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG} $DOCDIR
git -C $DOCDIR checkout gh-pages || git -C $DOCDIR checkout --orphan gh-pages

cp _build/*.docdir/* $DOCDIR

git -C $DOCDIR config user.email "travis@travis-ci.org"
git -C $DOCDIR config user.name "Travis"
git -C $DOCDIR add .
git -C $DOCDIR commit --allow-empty -m "Travis build $TRAVIS_BUILD_NUMBER pushed docs to gh-pages"
git -C $DOCDIR push origin gh-pages > /dev/null
