sudo add-apt-repository "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted universe"
sudo add-apt-repository --yes ppa:avsm/ocaml42+opam12
sudo apt-get update -qq
sudo apt-get install -y ocaml-compiler-libs ocaml-interp ocaml-base-nox ocaml-base ocaml ocaml-nox ocaml-native-compilers camlp4 camlp4-extra opam

export OPAMYES=1
opam init -a
opam pin add local-package . -n
opam install local-package --deps-only --build-test

eval `opam config env`
./configure --enable-tests
make
make test
make install
make uninstall
