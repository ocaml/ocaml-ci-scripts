# Travis CI scripts

## Plain OCaml Install, `.travis-ocaml.sh`

This is a helper script that simply installs the Ubuntu OCaml compiler packages,
including Camlp4, plus OPAM. This is fetched and executed by the other Travis
scripts in this repo. Set the `OCAML_VERSION` variable to the desired version,
e.g.,

```yaml
env:
  - OCAML_VERSION=4.02 [...]
```

### Testing Multiple Compilers

```yaml
env:
  - OCAML_VERSION=3.12 [...]
  - OCAML_VERSION=4.00 [...]
  - OCAML_VERSION=4.01 [...]
  - OCAML_VERSION=4.02 [...]
  - OCAML_VERSION=latest [...]
```

Add one line per compiler version you want to test. `latest` is the latest
stable version of OCaml. The `[...]` are other environments variables set for
this Travis CI run.

### Changing the Base OPAM Remote

```yaml
env:
  - [...] BASE_REMOTE=<url> [...]
```

The bare-bones install script can be configured to initialize OPAM with
a metadata repository that isn't the default community OPAM remote of
[git://github.com/ocaml/opam-repository](git://github.com/ocaml/opam-repository).
`BASE_REMOTE` initializes OPAM with a repository address of your choice.

## OPAM Package, `.travis-opam.sh`

Instructions:

1. Create an `opam` file at the root of your project. If you use opam
   1.2, you can simply do `opam pin add PKG .` -- this will open an
   editor and propose you a template.

2. Copy [.travis.yml](https://raw.githubusercontent.com/ocaml/ocaml-ci-scripts/master/.travis.yml)
   at the root of your project.

3. Enable Travis runs on
   `https://travis-ci.org/profile/<YOURGITHUBID>` (sign in with your
   Github account and click on `+` on top of the left pane).

And that's it! You can have more control over the things that Travis
CI is testing by looking at the next sections.


### Setting the Package Name

```yaml
env:
  - [...] PACKAGE=<name of your package> [...]
```

By default, the script will use `my-package` as package name, which
might not be what you want if your tests consist of installing reverse
dependencies.


### Basic Run

```yaml
env:
  - [...] INSTALL=<bool> [...]
```

By default, the script will start by doing a basic installation
run. Use `INSTALL=false` to disable that run.


### Optional Dependencies

The script will make a run where it will try to install all of the
optional dependencies which are specified before installing the
current package.

This information is read from the `opam` file per default, but it is also
possible to specify sets of optional dependencies that will be tried instead,
e.g. for testing multiple configurations with different set of dependencies.
These package names do not need to be defined in the `opam` file, they can be
any package in the OPAM repository.

```yaml
env:
  - [...] DEPOPTS="<list of space-separated package names>" [...]
```

All optional dependencies declared in the `opam` file may be installed
with

```yaml
env:
  - [...] DEPOPTS="*" [...]
```

An empty value or the value "false" will disable the optional dependency
run. If `TESTS` is `true` (default, see below), the package's tests will
be run during the optional dependency run as well.

### Extra Dependencies

Optional dependencies will be installed only in the optional dependencies run
but are not available during the normal run. But there might be a case when a
package is required but not part of the `opam` file. One example for this is
`oasis`, which needs to be installed before attempting to build the package.

```yaml
env:
  - [...] EXTRA_DEPS="<list of space-separated package names>" [...]
```

### Running the Tests

```yaml
env:
  - [...] TESTS=<bool> [...]
```

By default, the script will finish by a test run. Use `TESTS=false` to
disable that run. By sure to have a `build-test` field in your opam file,
otherwise this step is useless.

TODO: check if the `build-test` field is empty in the `opam` file to
know if the tests have to run.


### Reverse Dependency Tests

Finally, the build of immediate reverse dependencies of the package
under test may be tested. Disabled with 'false' by default, set
`REVDEPS=*` to build the freshest version of every dependent package
allowed by constraints. If you desire to test only specific dependent
packages, they may be provided in a space-separated list.

```yaml
env:
  - [...] REVDEPS="<list of space-separated package names>" [...]
```

### Customizing the OPAM Pin Set

```yaml
env:
  - [...] PINS="<list of space-separated name:url pin pairs>" [...]
```

You can customize the development pins of an OPAM package test run with
the `PINS` variable. Each pin specified will *only* result in that pin
being added into OPAM's pin set -- no default installation will be
performed. A pin of a package name without a colon (":") will result in
that package being pinned to the URL in that package's `dev-repo`
field. A pin of a `name:url` or `name.version:url` pair will pin the
package to the given URL.

### Hooks

```yaml
env:
  - [...] PRE_INSTALL_HOOK="multiple; shell; commands" [...]
  - [...] POST_INSTALL_HOOK="multiple; shell; commands" [...]
```

If you want to execute some commands before or after the installation, use
`PRE_INSTALL_HOOK="command1; command2"` or similarly `POST_INSTALL_HOOK`.
These only get executed when installing your package, not the dependencies.

The hook functionality might be useful for running commands like OASIS to
generate build files which are not checked into the repository.

### Changing OPAM Remotes

```yaml
env:
  - [...] EXTRA_REMOTES="<list of space-separated URLs>" [...]
```

In addition to changing the `BASE_REMOTE` to configure an initialization
repository, `.travis-opam.sh` users can layer additional OPAM remotes on top
of the `BASE_REMOTE` with `EXTRA_REMOTES`. Remotes are added from left
to right.

## GCC and binutils

```yaml
env:
 - [...] UPDATE_GCC_BINUTILS=1 [...]
```

Travis has a rather arcane `gcc` (4.6.3) and `binutils` (2.22). Some
pieces of C code require newer versions (e.g. intrinsics for
RDSEED). If `UPDATE_GCC_BINUTILS` is set to a non-zero value,
`gcc-4.8` and `binutils-2.24` are installed before running the build.

## Ubuntu Trusty

By default, Travis CI is using Ubuntu Precise. To add the PPA for
Ubuntu Trusty, use:

```yaml
env:
  - [...] UBUNTU_TRUSTY=1 [...]
```

*Note:* mixing Trusty and Precise PPAs might cause some issues with
 `apt-get update -u` when using some external dependencies.

## Mirage Unikernels, `.travis-mirage.sh`

This causes Travis to build a repo as a Mirage unikernel. It assumes the
existence of a `Makefile` at the root of the repo having targets `configure` and
`build`. Configuration choices are passed to the `make configure` target via
environment variables:

+ `DEPLOY=[1|...]`: if set to `1` then requests a deployment build
+ `MIRAGE_BACKEND=[unix|xen]`: selects Mirage backend mode
+ `MIRAGE_NET=[socket|direct]`: selects Mirage network stack

If a deployment build is requested then the corresponding Mirage `-deployment`
repo is cloned, the Xen VM image that was built is committed to it and the
`latest` pointer updated, and then the keys embedded in the `.travis.yml` file
are used to push the updated `-deployment` repo back to the `mirage` org.

### Changing the version of OPAM

```yaml
  - [...] OPAM_VERSION="1.1.2"
```

By default, the latest stable version of OPAM will be used. The scripts supports
these version:

- `OPAM_VERSION=1.1.2` only when the OS is `unix` (default)
- `OPAM_VERSION=1.2.0` only when the OS is `unix` (default)
- `OPAM_VERSION=1.2.2` when the OS is either `unix` or `osx`
- `OPAM_VERSION=1.3.0` only when the OS is `osx`

### Testing on different OS

See http://docs.travis-ci.com/user/multi-os/

Add the following to your `.travis.yml`:

```yaml
os:
  - linux
  - osx
```

## Pushing OCamldoc docs to Github page, `.travis-docgen.sh`

This relies on the existence of a `configure` script and `Makefile` such that
the docs are built as follows:

```shell
./configure --enable-docs
make doc
```

It also relies on you uploading an OAuth token to your Travis job. To do this,
create a token on your Github account settings page and upload it as follows:

```shell
gem install travis
travis encrypt GH_TOKEN=<token> --add
```

It will then push the contents of the resulting `<lib>.docdir` to the Github
pages branch of your repo.
