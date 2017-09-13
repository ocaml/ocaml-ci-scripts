FROM ocaml/opam:alpine as base

RUN opam depext -iy jbuilder

COPY . /home/opam/src/travis-opam
RUN sudo chown opam.nogroup -R /home/opam/src/travis-opam

WORKDIR /home/opam/src/travis-opam

RUN sed -i "s/^;\(.*static.*\)$/\1/" src/jbuild
RUN opam config exec -- jbuilder build
RUN sudo cp /home/opam/src/travis-opam/_build/default/src/ci_opam.exe /usr/bin/ci-opam

FROM scratch

USER 0
COPY --from=base /usr/bin/ci-opam /ci-opam
ENTRYPOINT ["/ci-opam"]
CMD []
