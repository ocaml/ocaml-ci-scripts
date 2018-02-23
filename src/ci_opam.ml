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
let default_pkg = "my-package"

let pkg =
  let pkg = getenv_default "PACKAGE" default_pkg in
  if pkg <> default_pkg then pkg
  else
    let files = Array.to_list (Sys.readdir ".") in
    let opams = List.filter (function file ->
        Filename.check_suffix file ".opam"
      ) files
    in
    match opams with
    | [f] -> (try Filename.chop_extension f with Invalid_argument _ -> f)
    | _   -> default_pkg

let pkg_name = try String.sub pkg 0 (String.index pkg '.') with Not_found -> pkg

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

(* run opam lint *)
let opam_lint = fuzzy_bool_of_string (getenv_default "OPAM_LINT" "true")

(* other variables *)
let extra_deps = list (getenv_default "EXTRA_DEPS" "")
let pre_install_hook = getenv_default "PRE_INSTALL_HOOK" ""
let post_install_hook = getenv_default "POST_INSTALL_HOOK" ""

let run_on_appveyor =
  try ignore(Sys.getenv "APPVEYOR"); true with Not_found -> false

(* Script *)

let add_remote =
  let layer = ref 0 in
  fun remote -> ?|~ "opam remote add extra%d %s" !layer remote; incr layer

let pin pin = match pair pin with
  | (pkg,None)     -> ?|~ "opam pin add %s --dev-repo -n" pkg
  | (pkg,Some url) -> ?|~ "opam pin add %s %s -n" pkg url

let is_base pkg =
  match trim (?|> "opam show -f version %s" pkg) with
  | "base" -> true
  | _ -> false

let filter_base pkgs =
  let baseless = List.filter (fun pkg -> not (is_base pkg)) (list pkgs) in
  baseless *~ " "

let with_opambuildtest fn =
  export "OPAMBUILDTEST" "1";
  let res = fn () in
  unset "OPAMBUILDTEST";
  res

(* Function taken from jsonm documentation *)
let json_of_src d =
  let dec d = match Jsonm.decode d with
    | `Lexeme l -> l
    | `Error _ | `End | `Await -> assert false
  in
  let rec value v k d = match v with
    | `Os -> obj [] k d  | `As -> arr [] k d
    | `Null | `Bool _ | `String _ | `Float _ as v -> k v d
    | _ -> assert false
  and arr vs k d = match dec d with
    | `Ae -> k (`A (List.rev vs)) d
    | v -> value v (fun v -> arr (v :: vs) k) d
  and obj ms k d = match dec d with
    | `Oe -> k (`O (List.rev ms)) d
    | `Name n -> value (dec d) (fun v -> obj ((n, v) :: ms) k) d
    | _ -> assert false
  in
  value (dec d) (fun v _ -> v) d

let obj = function `O x -> x | _ -> raise Not_found
let maybe_arr = function `A x -> x | `O x -> List.map snd x | _ -> []
let str = function `String x -> x | _ -> raise Not_found

let get_package_versions_from_json file =
  let file = open_in file in
  let decoder = Jsonm.decoder (`Channel file) in
  let pkgs =
    let get_pkg_ver o =
      let name = str (List.assoc "name" o) in
      let version = str (List.assoc "version" o) in
      if name = pkg_name then [] else [name ^ "." ^ version]
    in
    let get_install o = get_pkg_ver (obj (List.assoc "install" o)) in
    let get_pkg elt = try get_install (obj elt) with Not_found -> [] in
    List.concat (List.map get_pkg (List.concat (List.map maybe_arr (maybe_arr (json_of_src decoder)))))
  in
  close_in file;
  pkgs

let install ?(depopts="") ?(tests=false) args =
  let install_deps = if tests then
      (* 'opam install --deps-only' would run the tests too,
       * which we don't want.
       * Even if we'd run it without OPAMBUILDTEST the test-only
       * dependencies would still run their tests during installataion
       * `opam list --depends-on` doesn't list the test-only dependencies.
       * *)
      with_opambuildtest (fun () ->
          let tmp = "solution.json" in
          let pkgs = (pkg :: depopts :: extra_deps) *~ " " in
          ?|~ "opam install --show-actions --json %s %s" tmp pkgs;
          get_package_versions_from_json tmp
        )
    else extra_deps in
  if install_deps <> [] then (
    let deps = (ql install_deps) *~ " " in
    let install_depext () = ?|. "opam depext -u %s" deps in
    if tests then
      with_opambuildtest install_depext
    else install_depext ();
    ?|~ "opam install --unset-root %s" deps
  );

  let args = if tests then "-t" :: args else args in

  ?|  pre_install_hook;
  ?|~ "opam install %s %s" pkg (ql args *~ " ");
  ?|  post_install_hook;

  match extra_deps with
  | [] -> ()
  | deps ->
    ?|. "opam remove -a %s" (filter_base ((ql deps) *~ " "))

let with_fold_travis name f =
  Printf.printf "travis_fold:start:%s\r%!" name;
  f ();
  Printf.printf "travis_fold:end:%s\r%!" name

let with_fold_appveyor name f =
  (* AppVeyor does not support folds in the log.  Use titles with ANSI
     colors. *)
  Printf.printf "\027[33;1m*\n* START %s\n*\n\027[0m%!" name;
  f ();
  Printf.printf "\027[33;1m*\n* END %s\n*\n\027[0m%!" name

let with_fold =
  if run_on_appveyor then with_fold_appveyor else with_fold_travis

let install_with_depopts depopts =
  with_fold "Installing.DEPOPTS" (fun () ->
      install ~tests:tests_run ~depopts ["-v"];
      ?|~ "opam remove %s -v" pkg;
      ?|~ "opam remove -a %s" (filter_base depopts);
    );
  if tests_run then with_fold "Installing.DEPOPTS.notests" begin
      fun () ->
        install ~tests:false ~depopts ["-v"];
        ?|~ "opam remove %s -v" pkg;
        ?|~ "opam remove -a %s" (filter_base depopts);
    end

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

;; (* Go go go *)

with_fold "Prepare" (fun () ->
    set "-ue";
    unset "TESTS";
    export "OPAMYES" "1";
    ?| "eval $(opam config env)";

    (* remotes *)
    let remotes =
      ?|> "opam remote list --short | grep -v default | tr \"\\n\" \" \""
    in
    if remotes <> "" then begin
      ?|. "opam remote remove %s" remotes
    end;
    List.iter add_remote extra_remotes;

    let (/) = Filename.concat in

    let opam =
      if Sys.file_exists (pkg_name ^ ".opam") then (pkg_name ^ ".opam")
      else if Sys.file_exists "opam"
           && Sys.is_directory "opam"
           && Sys.file_exists ("opam" / "opam")
      then ("opam" / "opam")
      else if Sys.file_exists "opam" then "opam"
      else
        Format.ksprintf failwith "No opam file found for %s, aborting." pkg_name
    in

    List.iter pin pins;
    (if opam_lint then ?|~ "opam lint %s" opam);
    ?|~ "opam pin add %s . -n" pkg;
    ?|  "eval $(opam config env)";
    ?|  "opam install depext";
    (* Install the external dependencies *)
    ?|~ "opam depext -u %s" pkg;
  );

with_fold "Simple" (fun () ->
    (* Install the OCaml dependencies *)
    ?|~ "opam install %s --deps-only" pkg;

    (* Simple installation/removal test *)
    if install_run then (
      install ["-v"];
      ?|~ "opam remove %s -v" pkg
    ) else
      echo "INSTALL=false, skipping the basic installation run.";
  );

with_fold "Simple.test" (fun () ->
    if tests_run then (
      (* run tests only for this package *)
      install ~tests:true ["-v"];
      ?|~ "opam remove %s -v" pkg
    ) else
      echo "TESTS=false, skipping the test run.";
  );

(* optional dependencies *)
with_fold "Simple.depopts" (fun () ->
    let depopts_run = match depopts_run with
      | [] | ["false"] -> None
      | ["*"] -> (* query OPAM *)
        let d =
          ?|> "opam show %s | grep -oP 'depopts: \\K(.*)' | sed 's/ | / /g'" pkg
        in
        Some d
      | depopts -> Some (depopts *~ " ")
    in
    match depopts_run with
    | None   -> echo "DEPOPTS=false, skipping the optional dependency run.";
    | Some d -> install_with_depopts d
  );

with_fold "Reverse.dependencies" (fun () ->
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
          if List.mem pkg pins then pkg::acc else begin
            match max_version pkg with
            | Some pkgv -> pkgv::acc
            | None -> echo "Skipping uninstallable REVDEP %s" pkg; acc
          end
        ) [] packages in
      let installable_count = List.length packages in
      echo "%d/%d REVDEPS installable" installable_count revdep_count;

      ignore (List.fold_left (fun i dependent ->
          echo "\nInstalling %s (REVDEP %d/%d)" dependent i installable_count;
          ?|~ "opam depext -u %s" dependent;
          ?|~ "opam install %s" dependent;
          ?|~ "opam remove %s" dependent;
          i + 1
        ) 1 packages)
  );
