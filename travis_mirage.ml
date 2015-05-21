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

(* Script *)

let add_remote =
  let layer = ref 0 in
  fun remote -> ?|~ "opam remote add extra%d %s" !layer remote; incr layer

let pin pin = match pair pin with
  | (pkg,None)     -> ?|. "opam pin add %s --dev-repo -n" pkg
  | (pkg,Some url) -> ?|. "opam pin add %s %s -n" pkg url

;;

(* Go go go *)

set "-ue";
export "OPAMYES" "1";
?| "eval $(opam config env)";

List.iter add_remote extra_remotes;

List.iter pin pins;
?|  "eval $(opam config env)";

?| "opam update -u";
?| "opam install mirage";
?| "DEPLOY=$DEPLOY MODE=$MIRAGE_BACKEND NET=$MIRAGE_NET \
    ADDR=$MIRAGE_ADDR MASK=$MIRAGE_MASK GWS=$MIRAGE_GWS \
    make configure";
?| "make build";

(*

## stash deployment build if specified
if [ "$DEPLOY" = "1" \
               -a "$TRAVIS_PULL_REQUEST" = "false" \
               -a -n "$XSECRET_default_0" ]; then
    opam install travis-senv
    # get the secure key out for deployment
    mkdir -p ~/.ssh
    SSH_DEPLOY_KEY=~/.ssh/id_dsa
    travis-senv decrypt > $SSH_DEPLOY_KEY
    chmod 600 $SSH_DEPLOY_KEY

    echo "Host mir-deploy github.com"      >> ~/.ssh/config
    echo "   Hostname github.com"          >> ~/.ssh/config
    echo "   StrictHostKeyChecking no"     >> ~/.ssh/config
    echo "   CheckHostIP no"               >> ~/.ssh/config
    echo "   UserKnownHostsFile=/dev/null" >> ~/.ssh/config

    git config --global user.email "travis@openmirage.org"
    git config --global user.name "Travis the Build Bot"
    git clone git@mir-deploy:${TRAVIS_REPO_SLUG}-deployment

    DEPLOYD=${TRAVIS_REPO_SLUG#*/}-deployment
    XENIMG=mir-${XENIMG:-$TRAVIS_REPO_SLUG#mirage/mirage-}.xen
    MIRDIR=${MIRDIR:-src}
    case "$MIRAGE_BACKEND" in
        xen)
            cd $DEPLOYD
            rm -rf xen/$TRAVIS_COMMIT
            mkdir -p xen/$TRAVIS_COMMIT
            cp ../$MIRDIR/$XENIMG ../$MIRDIR/config.ml xen/$TRAVIS_COMMIT
            bzip2 -9 xen/$TRAVIS_COMMIT/$XENIMG
            echo $TRAVIS_COMMIT > xen/latest
            git add xen/$TRAVIS_COMMIT xen/latest
            ;;
(*        *)
            echo unsupported deploy mode: $MIRAGE_BACKEND
            exit 1
            ;;
    esac
    git commit -m "adding $TRAVIS_COMMIT for $MIRAGE_BACKEND"
    git push
fi

*)
