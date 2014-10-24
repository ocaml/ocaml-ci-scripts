wget https://raw.githubusercontent.com/samoht/ocaml-travisci-skeleton/master/.travis-opam.sh
sh .travis-opam.sh

eval `opam config env`
./configure --enable-tests
make
make test
make install
make uninstall
