wget https://github.com/samoht/ocaml-travisci-skeleton/blob/master/.opam-travis.sh
chmod +x opam-travis.sh
./opam-travis.sh

eval `opam config env`
./configure --enable-tests
make
make test
make install
make uninstall
