# If a fork of these scripts are specified, use that GitHub user instead
fork_user=${FORK_USER:-ocaml}

### Bootstrap

set -uex
unset TESTS

get() {
  wget https://raw.githubusercontent.com/${fork_user}/ocaml-travisci-skeleton/master/$@
}

TMP_BUILD=$(mktemp -d)
cd ${TMP_BUILD}

get .travis-ocaml.sh
get yorick.mli
get yorick.ml
get travis_opam.ml

sh .travis-ocaml.sh
export OPAMYES=1
eval $(opam config env)

# This could be removed with some OPAM variable plumbing into build commands
opam install ocamlfind

ocamlc.opt yorick.mli
ocamlfind ocamlc -c yorick.ml

ocamlfind ocamlc -o travis-opam -package unix -linkpkg yorick.cmo travis_opam.ml
cd -

${TMP_BUILD}/travis-opam
