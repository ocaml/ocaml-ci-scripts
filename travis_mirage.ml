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

(* Mirage deployment environment *)
let (|>) a b = b a
let is_deploy = getenv_default "DEPLOY" "false" |> fuzzy_bool_of_string
let is_travis_pr =
  getenv_default "TRAVIS_PULL_REQUEST" "false" |> fuzzy_bool_of_string
let have_secret =
  getenv_default "XSECRET_default_0" "false" |> fuzzy_bool_of_string
let is_xen =
  getenv_default "MIRAGE_BACKEND" "" |> function "xen" -> true | _ -> false
let travis_branch = getenv_default "TRAVIS_BRANCH" ""

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
?| "eval $(opam config env)";

?| "opam update -u";
?| "opam install mirage";
?| "MODE=$MIRAGE_BACKEND make configure";
?| "make build";
?| "echo TRAVIS_BRANCH=$TRAVIS_BRANCH"
;;

if is_deploy && is_xen && have_secret && (not is_travis_pr) &&
   travis_branch = "master"
then begin
  let ssh_config = "Host mir-deploy github.com
                   \  Hostname github.com
                   \  StrictHostKeyChecking no
                   \  CheckHostIP no
                   \  UserKnownHostsFile=/dev/null"
  in
  export "XENIMG" "mir-${XENIMG:-$TRAVIS_REPO_SLUG#mirage/mirage-}.xen";
  export "MIRDIR" "${MIRDIR:-src}";
  export "DEPLOYD" "${TRAVIS_REPO_SLUG#*/}-deployment";

  (* setup ssh *)
  ?|  "opam install travis-senv";
  ?|  "mkdir -p ~/.ssh";
  ?|  "travis-senv decrypt > ~/.ssh/id_dsa";
  ?|  "chmod 600 ~/.ssh/id_dsa";
  ?|~ "echo '%s' > ~/.ssh/config" ssh_config;
  (* configure git for github *)
  ?|  "git config --global user.email 'travis@openmirage.org'";
  ?|  "git config --global user.name 'Travis the Build Bot'";
  ?|  "git config --global push.default simple";
  (* clone deployment repo *)
  ?|  "git clone git@mir-deploy:${TRAVIS_REPO_SLUG}-deployment";
  (* remove and recreate any existing image for this commit *)
  ?|  "rm -rf $DEPLOYD/xen/$TRAVIS_COMMIT";
  ?|  "mkdir -p $DEPLOYD/xen/$TRAVIS_COMMIT";
  ?|  "cp $MIRDIR/$XENIMG $MIRDIR/config.ml $MIRDIR/*.xl.in $DEPLOYD/xen/$TRAVIS_COMMIT";
  ?|  "bzip2 -9 $DEPLOYD/xen/$TRAVIS_COMMIT/$XENIMG";
  ?|  "echo $TRAVIS_COMMIT > $DEPLOYD/xen/latest";
  (* commit and push changes *)
  ?|  "cd $DEPLOYD &&\
       \ git add xen/$TRAVIS_COMMIT xen/latest &&\
       \ git commit -m \"adding $TRAVIS_COMMIT for $MIRAGE_BACKEND\" &&\
       \ git push"
end
