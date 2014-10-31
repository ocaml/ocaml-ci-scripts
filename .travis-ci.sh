wget https://raw.githubusercontent.com/samoht/ocaml-travisci-skeleton/master/.travis-opam.sh

## Comment the following line to NOT `opam install` the current package
# export OPAM_INSTAL=false

sh .travis-opam.sh

## You can add some custom test scripts here.
# eval `opam config env`
# prefix=`opam config var prefix`
