# Travis CI scripts

## Plain OCaml Install, `.travis-ocaml.sh`

This is a helper script that simply installs the Ubuntu OCaml compiler packages,
including Camlp4, plus opam. This is fetched and executed by the other Travis
scripts in this repo. Set the `OCAML_VERSION` variable to the desired version,
e.g.,

```yaml
env:
  - OCAML_VERSION=4.02 [...]
```

**Note:** Setting the `OCAML_VERSION` to `latest` is no longer valid, and there is
no default `OCAML_VERSION`; you must set one, either per-entry or once in the global
section for all tests.  For discussion, please see
[the issue](https://github.com/ocaml/ocaml-ci-scripts/issues/110) in which
updating `OCAML_VERSION` from version 4.02.3 was initially proposed.

### Testing Multiple Compilers

```yaml
env:
  - OCAML_VERSION=4.02 [...]
  - OCAML_VERSION=4.05 [...]
  - OCAML_VERSION=4.07 [...]
  - OCAML_VERSION=4.08 [...]
  - OCAML_VERSION=4.09 [...]
```

Add one line per compiler version you want to test. The `[...]` are other
environments variables set for this Travis CI run.

### Changing the Base opam Remote

```yaml
env:
pick  - [...] BASE_REMOTE=<url> [...]
```

The bare-bones install script can be configured to initialize opam with
a metadata repository that isn't the default community opam remote of
[git://github.com/ocaml/opam-repository](git://github.com/ocaml/opam-repository).
`BASE_REMOTE` initializes opam with a repository address of your choice.

### Testing a specific switch

The `OCAML_VERSION` variable will select the latest release of that version. If
you require a specific release (for example a beta or release candidate), you
can set `OPAM_SWITCH` to the precise compiler to be used. `OPAM_SWITCH` takes
precedence over `OCAML_VERSION`.

### Testing system switches

It is possible to test a specific compiler as though it were a system switch by
setting the environment variable `INSTALL_LOCAL` to `1`. In this case,
`OPAM_SWITCH` must be either empty, un-set or `system`. The script will compile
the latest release of `OCAML_VERSION` and install it to `/usr/local/` which opam
will then pick up as a system compiler instead of the Ubuntu-installed OCaml.

This process does not install camlp4, though Ubuntu does (at least at present)
install camlp4 4.02.3 with opam. If you require camlp4 for the compiler, you
will need to install it as part of your test script using opam.

At present, this feature is only available on Ubuntu Travis images and will
return an error if specified for a macOS image.

## opam Package, `.travis-opam.sh`

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
any package in the opam repository.

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

### Customizing the opam Pin Set

```yaml
env:
  - [...] PINS="<list of space-separated name:url pin pairs>" [...]
```

You can customize the development pins of an opam package test run with
the `PINS` variable. Each pin specified will *only* result in that pin
being added into opam's pin set -- no default installation will be
performed. A pin of a package name without a colon (":") will result in
that package being pinned to the URL in that package's `dev-repo`
field. A pin of a `name:url` or `name.version:url` pair will pin the
package to the given URL.

### Building with new and not yet published packages

```yaml
env:
  - [...] PINS="ounit2.2.2.0:. ounit2-lwt.2.2.0:." [...]
```

If you start a project from scratch and use these scripts without a
pre-existing package in OPAM, you need to pin the package to a precise
version directly in the environment. This will allow to install the
package and other dependencies correctly.

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

### Changing opam Remotes

```yaml
env:
  - [...] EXTRA_REMOTES="<list of space-separated URLs>" [...]
```

In addition to changing the `BASE_REMOTE` to configure an initialization
repository, `.travis-opam.sh` users can layer additional opam remotes on top
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

This causes Travis to build a repo as a Mirage unikernel.  The location of the
unikernel within the repository may be specified by setting the SRC_DIR variable.
Configuration choices are passed to `mirage configure` via environment variables:

+ `MIRAGE_BACKEND=[unix|xen|qubes|virtio|ukvm|macosx]`: selects Mirage backend mode
+ `FLAGS`: other configuration flags to set in `mirage configure`

### Changing the version of opam

By default, the CI scripts are using the latest release of opam *2.0.1*.
To use a different version of opam, use:

```yaml
  - [...] OPAM_VERSION="1.2.2"
 ```

Supported versions are `2.0.0`, `1.2.2`, `1.2.0` and `1.1.2`.

### Testing on different OS

See http://docs.travis-ci.com/user/multi-os/

Add the following to your `.travis.yml`:

```yaml
os:
  - freebsd
  - linux
  - osx
```

To enable XQuartz support on MacOS, use:

```yaml
  - [...] INSTALL_XQUARTZ=true
```

### Testing on different architecture

See https://docs.travis-ci.com/user/multi-cpu-architectures/

Add the following to your `.travis.yml`:

```yaml
arch:
  - amd64
  - arm64
```

For the moment only AMD64 (x86_64) and ARM64 (AArch64) are supported by our script.

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
