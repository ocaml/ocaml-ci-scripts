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
let revdep_run = list (getenv_default "REVDEPS" "")

(* other variables *)
let extra_deps = some (getenv_default "EXTRA_DEPS" "")
let pre_install_hook = getenv_default "PRE_INSTALL_HOOK" ""
let post_install_hook = getenv_default "POST_INSTALL_HOOK" ""

(* Script *)

let some x = Some x

let add_remote =
  let layer = ref 0 in
  fun remote -> ?|~ "opam remote add extra%d %s" !layer remote; incr layer

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

let install_with_depopts depopts =
  ?|~ "opam depext %s" depopts;
  ?|~ "opam install %s" depopts;
  install ["-v"];
  ?|~ "opam remove %s -v" pkg;
  ?|~ "opam remove %s" depopts

let max_version package =
  let rec next_version last =
    match ?|? "opam install --dry-run %s.%s > /dev/null" package last with
    | 0 -> Some (package^"."^last)
    | _ ->
      match !?* (?|>) "opam show -f version \'%s<%s\'" package last with
      | v, 0 -> next_version (trim v)
      | _ -> None
  in
  next_version (trim (?|> "opam show -f version %s" package))

let with_opambuildtest fn =
  export "OPAMBUILDTEST" "1";
  fn ();
  unset "OPAMBUILDTEST"

;; (* Go go go *)

set "-ue";
unset "TESTS";
export "OPAMYES" "1";
?| "eval $(opam config env)";

List.iter add_remote extra_remotes;

List.iter pin pins;
?|. "opam pin add %s . -n" pkg;
?|  "eval $(opam config env)";

(* Install the external dependencies *)
?|~ "opam depext %s" pkg;

(* Install the OCaml dependencies *)
?|~ "opam install %s --deps-only" pkg;

begin (* Simple installation/removal test *)
  if install_run then (
    install ["-v"];
    ?|~ "opam remove %s -v" pkg
  ) else
    echo "INSTALL=false, skipping the basic installation run.";
end;

begin (* tests *)
  if tests_run then
    with_opambuildtest (fun () ->
        ?|~ "opam depext %s" pkg;
        ?|~ "opam install %s --deps-only" pkg;
        install ["-v";"-t"];
        ?|~ "opam remove %s -v" pkg)
  else
    echo "TESTS=false, skipping the test run.";
end;

begin (* optioanal dependencies *)
  let depopts_run = match depopts_run with
    | [] | ["false"] -> None
    | ["*"] -> (* query OPAM *)
      ?|> "opam show %s | grep -oP 'depopts: \\K(.*)' | sed 's/ | / /g'" pkg
      |>  some
    | depopts -> Some (depopts *~ " ")
  in
  match depopts_run with
  | None   -> echo "DEPOPTS=false, skipping the optional dependency run.";
  | Some d -> install_with_depopts d
end;

begin (* reverse dependencies *)
  let revdeps = match revdep_run with
    | [] | ["false"] | ["0"] -> None
    | ["*"] | ["true"] | ["1"] ->
      let revdep_cmd = ~~ "opam list --depends-on %s --short" in
      (match !?* (?|>) revdep_cmd pkg with
       | ls, 0 -> Some (lines ls)
       | ls, 1 when lines ls = [] -> Some []
       | _,  x ->
         Printf.eprintf "'%(%s%)' exited %d. Terminating with %d\n"
           revdep_cmd pkg x x;
         exit x
      )
    | packages -> Some packages
  in
  match revdeps with
  | None -> echo "REVDEPS=false, skipping the reverse dependency rebuild run."
  | Some packages ->
    let revdep_count = List.length packages in
    echo "\nREVDEPS %d total" revdep_count;
    let packages = List.fold_left (fun acc pkg ->
        match max_version pkg with
        | Some pkgv -> pkgv::acc
        | None -> echo "Skipping uninstallable REVDEP %s" pkg; acc
      ) [] packages in
    let installable_count = List.length packages in
    echo "%d/%d REVDEPS installable" installable_count revdep_count;

    ignore (List.fold_left (fun i dependent ->
        echo "\nInstalling %s (REVDEP %d/%d)" dependent i installable_count;
        ?|~ "opam depext %s" dependent;
        ?|~ "opam install %s" dependent;
        ?|~ "opam remove %s" dependent;
        i + 1
      ) 1 packages)
end;
