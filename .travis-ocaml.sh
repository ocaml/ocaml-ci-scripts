## basic OCaml and opam installation

set -uex

# the ocaml version to test
OCAML_VERSION=${OCAML_VERSION:-latest}

case "$OCAML_VERSION" in
    3.12) echo Pre 4.00 compilers are unsupported; exit 1 ;;
    4.00) ppa=avsm/ocaml40+opam12  ;;
    4.01) ppa=avsm/ocaml41+opam12  ;;
    4.02) ppa=avsm/ocaml42+opam12  ;;
    *)    ppa=avsm/ocaml42+opam12  ;;
esac

sudo add-apt-repository \
     "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted universe"
sudo add-apt-repository --yes ppa:${ppa}
sudo apt-get update -qq
sudo apt-get install -y \
     ocaml ocaml-base ocaml-native-compilers ocaml-compiler-libs ocaml-interp \
     ocaml-base-nox ocaml-nox camlp4 camlp4-extra opam

ocaml -version

export OPAMYES=1

opam init -a git://github.com/ocaml/opam-repository
eval $(opam config env)
opam install depext

opam --version
opam --git-version
