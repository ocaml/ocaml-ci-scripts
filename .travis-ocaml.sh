## basic OCaml and opam installation

set -uex

wget https://downloads.sourceforge.net/project/zero-install/0install/2.8/0install-linux-x86_64-2.8.tar.bz2
tar xjf 0install-linux-x86_64-2.8.tar.bz2
cd 0install-linux-x86_64-2.8
./install.sh home
export PATH=$HOME/bin:$PATH
0install add opam http://tools.ocaml.org/opam.xml


# the base opam repository to use for bootstrapping and catch-all namespace
BASE_REMOTE=${BASE_REMOTE:-git://github.com/ocaml/opam-repository}

ocaml -version

export OPAMYES=1

opam init -a ${BASE_REMOTE}
eval $(opam config env)
#opam install depext

opam --version
opam --git-version
