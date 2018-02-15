### 1.2.0 (2018-02-14)

* Use jbuilder (#180, @samoht)
* Add a Dockerfile and runes to push an image to Docker Hub (#183, @samoht)
* Support BASE_REMOTE in .travis-docker.sh (#188, @edwintorok)
* Add OCaml 4.06 support (#190, #191, @andyli and @gasche)
* Remove `latest` as a supported compiler version
  (#192, #203, @hannesm and @yomimono)
* Fix deployment logic for travis-mirage (#195 #198, @yomimono and @samoht)
* Add an ISC license to the project (#204, @samoht)
* Allow the user to specify the Docker hub user from which to get the base image
  (#200, @yomimono)
* Don't try to deduce the maximum version of pinned revdeps (#207, @yomimono)
* INSTALL_LOCAL option: allowing a specific compiler to be tested as a "system"
  compiler (#202, @dra27)
* Replace jq uses by jsonm (#211, #215, #216, @jpdeplaix)

### 1.1.0 (2017-09-11)

* Rename travis-opam into ci-opam (#101, @avsm)
* Do not run the tests of dependencies (#145, @edwintorok)
* Run depopts tests (#146, @edwintorok)
* Allow to use `PACKAGE=name.version` (#152, @samoht)
* Improve log outputs (folding, more debug message, etc
  (@Chris00, @edwintorok, @samoht)
* Automatically infer package name when using `pkg.opam` (#181, @samoht)

### 1.0.3 (2016-11-23):

* Always run `depext -u` to update the base OS (#138)
* Don't attempt to remove base-* packages which will always fail (#93)
* Complete the Appveyor CI scripts to be on-par with those for Travis CI (#101)

### 1.0.2 (2016-03-01):

* Docker: Update package metadata before installing depexts (#80)
* Docker: Refresh origin OPAM repository to latest master upon build (#79)
* Better detection of `opam` files. Some repos can contain multiple `opam`
  files (e.g. mirage/mirage contains mirage and mirage-types), so we need
  to look for `<pkg>.opam`.

### 1.0.1 (2016-01-08):

* Lint opam file before pinning to avoid edit loops (#75)

### 1.0.0 (2016-01-05):

* Initial opam release
