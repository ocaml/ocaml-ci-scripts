.PHONY: all clean

all:
	ocamlbuild -tag use_unix travis_opam.byte
	ocamlbuild -tag use_unix travis_mirage.byte

clean:
	rm -rf _build
