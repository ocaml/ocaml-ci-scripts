Simple container to reproduce travis builds for opam packages. Something like this should work from the package's project root:

```
docker run \
  -v ${PWD}:/build \
  -e PACKAGE=<package-name> \
  -e OCAML_VERSION=4.03 \
  -e EXTRA_REMOTES=<remote-url>
  -ti fgimenez/ocaml-travis-runner
```

You can add `bash` at the end of the command to open a shell on the container and execute individual steps manually (the runner script is at `/build-script/travis-runner.sh`).
