# Appveyor CI scripts

Instructions:

1. Create an `opam` file at the root of your project. If you use opam
   1.2, you can simply do `opam pin add PKG .` -- this will open an
   editor and propose you a template.

2. Copy [appveyor.yml](https://raw.githubusercontent.com/ocaml/ocaml-ci-scripts/master/appveyor.yml)
   at the root of your project.

3. Enable Appveyor runs on
   https://ci.appveyor.com/projects (sign in with your
   Github account and click on `+` on the top pane).

And that's it!

### Options

Most of the options detailed in TravisCI scripts are valid.
