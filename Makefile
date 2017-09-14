.PHONY: all clean

all:
	jbuilder build --dev

clean:
	jbuilder clean

push:
	docker build . -t ocaml/ci-opam
	docker push ocaml/ci-opam
