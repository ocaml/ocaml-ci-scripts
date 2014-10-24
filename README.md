## Travis CI skeleton for OCaml projects

1. Create an `opam` file at the root of your project. If you use opam
   1.2, you can simply do `opam pin add PKG .` -- this will open an
   editor and propose you a template.

2. Copy `.travis.yml` and `.travis-ci.sh` at the root of your project.

3. (optional) If needed, update `.travis-ci.sh` to tweaks the commands
   to run to test your project.

4. Enable Travis runs on `https://travis-ci.org/profile/<YOURGITHUBID>`