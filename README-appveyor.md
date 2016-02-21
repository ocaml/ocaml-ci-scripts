# Appveyor CI scripts

Instructions:

1. Create an `opam` file at the root of your project. If you use opam
   1.2, you can simply do `opam pin add PKG .` -- this will open an
   editor and propose you a template.

2. Copy `appveyor.yml` at the root of your project.

3. Enable Appveyor runs on
   `https://ci.appveyor.com/projects` (sign in with your
   Github account and click on `+` on the top pane).

And that's it!

Currently, the CI simply pin the local repository and try to compile it with
[mingw-w64](https://fdopen.github.io/opam-repository-mingw/). There is no
depots, tests, etc.. options as for Travis CI scripts (yet).
