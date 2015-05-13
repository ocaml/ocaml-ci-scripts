## basic OCaml and opam installation

set -uex

# the base opam repository to use for bootstrapping and catch-all namespace
BASE_REMOTE=${BASE_REMOTE:-git://github.com/ocaml/opam-repository}

ocaml -version

export OPAMYES=1

opam init -a ${BASE_REMOTE}
eval $(opam config env)
#opam install depext

opam --version
opam --git-version
