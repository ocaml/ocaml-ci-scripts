(*
 * Copyright (c) 2015 David Sheets <sheets@alum.mit.edu>
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

(* The package name *)
let pkg = getenv_default "PACKAGE" "my-package"

(* Extra remotes to stack on top of the initialization remote *)
let extra_remotes = list (getenv_default "EXTRA_REMOTES" "")

(* Any extra pins to use *)
let pins = list (getenv_default "PINS" "")

(* Run the basic installation step *)
let install_run = fuzzy_bool_of_string (getenv_default "INSTALL" "true")

(* Run the optional dependency step *)
let depopts_run = list (getenv_default "DEPOPTS" "")

(* Run the test step *)
let tests_run = fuzzy_bool_of_string (getenv_default "TESTS" "true")

(* Run the reverse dependency rebuild step *)
let revdep_run = fuzzy_bool_of_string (getenv_default "REVDEPS" "false")

(* other variables *)
let extra_deps = some (getenv_default "EXTRA_DEPS" "")
let pre_install_hook = getenv_default "PRE_INSTALL_HOOK" ""
let post_install_hook = getenv_default "POST_INSTALL_HOOK" ""

(* Script *)

let add_remote =
  let layer = ref 0 in
  fun remote -> ?|. "opam remote add extra%d %s" !layer remote; incr layer

let pin pin = match pair pin with
  | (pkg,None)     -> ?|. "opam pin add %s --dev-repo -n" pkg
  | (pkg,Some url) -> ?|. "opam pin add %s %s -n" pkg url

let install args =
  begin match extra_deps with
    | None -> ()
    | Some deps ->
      ?|. "opam depext %s" deps;
      ?|. "opam install %s" deps
  end;

  ?|  pre_install_hook;
  ?|~ "opam install %s %s" pkg (ql args *~ " ");
  ?|  post_install_hook;

  begin match extra_deps with
    | None -> ()
    | Some deps ->
      ?|. "opam remove %s" deps
  end

let install_with_depopts args depopts =
  ?|~ "opam depext %s" depopts;
  ?|~ "opam install %s" depopts;
  install args;
  ?|~ "opam remove %s -v" pkg;
  ?|~ "opam remove %s" depopts

let is_installable package =
  match ?|? "opam install --dry-run %s" package with 0 -> true | _ -> false

;;
(* Go go go *)

set "-ue";
unset "TESTS";
export "OPAMYES" "1";
?|  "eval $(opam config env)";

List.iter add_remote extra_remotes;

List.iter pin pins;
?|. "opam pin add %s . -n" pkg;
?|  "eval $(opam config env)";

(* Install the external dependencies *)
?|~ "opam depext %s" pkg;

(* Install the OCaml dependencies *)
?|~ "opam install %s --deps-only" pkg;

(* Simple installation/removal test *)
if install_run
then begin
  install ["-v"];
  ?|~ "opam remove %s -v" pkg
end else echo "INSTALL=false, skipping the basic installation run."
;

(* Compile and run the tests as well *)
if tests_run
then begin
  ?|~ "opam install %s --deps-only -t" pkg;
  install ["-v";"-t"];
  ?|~ "opam remove %s -v" pkg
end else echo "TESTS=false, skipping the test run."
;

(* Compile with optional dependencies *)
begin match depopts_run with
  | [] | ["false"] ->
    echo "DEPOPTS=false, skipping the optional dependency run."
  | ["*"] -> (* query OPAM *)
    let depopts =
      ?|> "opam show %s | grep -oP 'depopts: \\K(.*)' | sed 's/ | / /g'" pkg
    in
    install_with_depopts ["-v"] depopts
  | depopts -> install_with_depopts ["-v"] (depopts *~ " ")
end;

if revdep_run
then
  let packages = lines (?|> "opam list --depends-on %s --short" pkg) in
  List.iter (fun dependent ->
    echo "Checking installability of revdep %s" dependent;
    if is_installable dependent
    then begin
      ?|~ "opam depext %s" dependent;
      ?|~ "opam install %s" dependent;
      ?|~ "opam remove %s" dependent;
    end
    else echo "%s found not installable. Skipping." dependent
  ) packages
else echo "REVDEPS=false, skipping the reverse dependency rebuild run."
