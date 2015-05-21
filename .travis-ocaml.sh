## basic OCaml and opam installation

full_apt_version () {
  package=$1
  version=$2
  case "${version}" in
      latest) echo -n "${package}" ;;
      *) echo -n "${package}="
         apt-cache show $package \
             | sed -n "s/^Version: \(${version}\)/\1/p" \
             | head -1
  esac
}

set -uex

# the ocaml version to test
OCAML_VERSION=${OCAML_VERSION:-latest}

# the base opam repository to use for bootstrapping and catch-all namespace
BASE_REMOTE=${BASE_REMOTE:-git://github.com/ocaml/opam-repository}

# whether we need a new gcc and binutils
UPDATE_GCC_BINUTILS=${UPDATE_GCC_BINUTILS:-"0"}

case "$OCAML_VERSION" in
    3.12) ppa=avsm/ocaml312+opam12 ;;
    4.00) ppa=avsm/ocaml40+opam12  ;;
    4.01) ppa=avsm/ocaml41+opam12  ;;
    4.02) ppa=avsm/ocaml42+opam12  ;;
    latest) ppa=avsm/ppa-opam-experimental;;
    *)    echo Unknown compiler version; exit 1;;
esac

sudo add-apt-repository \
     "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted universe"
sudo add-apt-repository --yes ppa:${ppa}
sudo apt-get update -qq
sudo apt-get install -y \
     $(full_apt_version ocaml $OCAML_VERSION) \
     $(full_apt_version ocaml-base $OCAML_VERSION) \
     $(full_apt_version ocaml-native-compilers $OCAML_VERSION) \
     $(full_apt_version ocaml-compiler-libs $OCAML_VERSION) \
     $(full_apt_version ocaml-interp $OCAML_VERSION) \
     $(full_apt_version ocaml-base-nox $OCAML_VERSION) \
     $(full_apt_version ocaml-nox $OCAML_VERSION) \
     $(full_apt_version camlp4 $OCAML_VERSION) \
     $(full_apt_version camlp4-extra $OCAML_VERSION) \
     opam

if [ "$UPDATE_GCC_BINUTILS" != "0" ] ; then
    echo "installing a recent gcc and binutils (mainly to get mirage-entropy-xen working!)"
    sudo add-apt-repository --yes ppa:ubuntu-toolchain-r/test
    sudo apt-get -qq update
    sudo apt-get install -y gcc-4.8
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 90
    wget http://mirrors.kernel.org/ubuntu/pool/main/b/binutils/binutils_2.24-5ubuntu3.1_amd64.deb
    sudo dpkg -i binutils_2.24-5ubuntu3.1_amd64.deb
fi

ocaml -version

export OPAMYES=1

opam init -a ${BASE_REMOTE}
eval $(opam config env)
opam install depext

opam --version
opam --git-version
