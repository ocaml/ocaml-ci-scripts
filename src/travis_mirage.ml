(*
 * Copyright (c) 2015 David Sheets <sheets@alum.mit.edu>
 *                    Richard Mortier <mort@cantab.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

(* First thing's first: conjure tools. *)

open Yorick

(* User-defined variables *)

(* Extra remotes to stack on top of the initialization remote *)
let extra_remotes = list (getenv_default "EXTRA_REMOTES" "")

(* Any extra pins to use *)
let pins = list (getenv_default "PINS" "")

(* Directory in which to build the unikernel *)
let dir = getenv_default "SRC_DIR" "."

(* Script *)

let add_remote =
  let layer = ref 0 in
  fun remote -> ?|~ "opam remote add extra%d %s" !layer remote; incr layer

let pin pin = match pair pin with
  | (pkg,None)     -> ?|. "opam pin add %s --dev-repo -n" pkg
  | (pkg,Some url) -> ?|. "opam pin add %s %s -n" pkg url

;;

(* Go go go *)

set "-ex";
export "OPAMYES" "1";
?| "eval $(opam config env)";

List.iter add_remote extra_remotes;

List.iter pin pins;
cd dir;
?| "eval $(opam config env)";

?| "opam update -u";
?| "opam install 'mirage>=3.0.0'";
?| "mirage configure -t $MIRAGE_BACKEND $FLAGS";
?| "make depend";
?| "make";
