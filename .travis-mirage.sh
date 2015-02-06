## mirage setup

set -ue

## first, fetch+execute the OCaml/opam setup script
wget https://github.com/mor1/ocaml-travisci-skeleton/.travis-ocaml.sh
sh .travis-ocaml.sh

## then, install mirage
export OPAMYES=1
eval $(opam config env)

opam install mirage
make configure
make
