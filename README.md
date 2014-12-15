## Travis CI skeleton for OCaml projects

Instructions:

1. Create an `opam` file at the root of your project. If you use opam
   1.2, you can simply do `opam pin add PKG .` -- this will open an
   editor and propose you a template.

2. Copy `.travis.yml` at the root of your project.

3. Enable Travis runs on
   `https://travis-ci.org/profile/<YOURGITHUBID>` (sign in with your
   Github account and click on `+` on top of the left pane).


### Testing Multiple Compilers

````shell
env:
  - OCAML_VERSION=3.12 [...]
  - OCAML_VERSION=4.00 [...]
  - OCAML_VERSION=4.01 [...]
  - OCAML_VERSION=4.02 [...]
  - OCAML_VERSION=latest [...]
````

Add one line per compiler version you want to test. `latest` is the
latest stable version of OCaml. The `[...]` are other environments
variables set for this Travis CI run (see next sections).


### Setting the Package Name

```shell
env:
  - [...] PACKAGE=<name of your package> [...]
```

By default, the script will use `my-package` as package name, which
might not be what you want if your tests consist of installing reverse
dependencies.


### Basic Run

```shell
env:
  - [...] INSTALL=<bool> [...]
```

By default, the script will start by doing a basic installation
run. Use `INSTALL=false` to disable that run.


### Optional Dependencies

```shell
env:
  - [...] DEPOPTS="<list of space-separated package names>" [...]
```

The script will make a run where it will try to install all of the
optional dependencies which are specified before installing the
current package.

TODO: read the optional dependencies in the `opam` file.


### Running the Tests

```shell
env:
  - [...] TESTS=<bool> [...]
```

By default, the script will finish by a test run. Use `TESTS=false` to
disable that run.
