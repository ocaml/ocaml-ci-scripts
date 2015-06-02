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

type ('a,'b) exec = ('a, unit, string, 'b) format4 -> 'a

(** Some shell-like operators *)
module Quips : sig
  (** [tokens *~ sep] is the string of [tokens] separated by [sep]. *)
  val ( *~ ) : string list -> string -> string

  (** [~~ fmt] is {!Pervasives.format_of_string} [fmt]. *)
  val ( ~~ ) :
    ('a, 'b, 'c, 'd, 'e, 'f) format6 -> ('a, 'b, 'c, 'd, 'e, 'f) format6

  (** [?|  command] executes [command] successfully. *)
  val ( ?|  ) : string -> unit

  (** [?|. command_pattern] is a function of [command_pattern] parameters
      which executes [command_pattern ...] successfully. *)
  val ( ?|. ) : ('a, unit) exec

  (** [?|~ command_pattern] is a function of [command_pattern] parameters
      which prints [command_pattern ...] and then executes it successfully. *)
  val ( ?|~ ) : ('a, unit) exec

  (** [?|> command_pattern] is a function of [command_pattern]
      parameters which returns a string of the stdout from
      [command_pattern ...]'s execution. *)
  val ( ?|> ) : ('a, string) exec

  (** [?|? command_pattern] is a function of [command_pattern]
      parameters which returns an int of the exit code from
      [command_pattern ...]'s execution. *)
  val ( ?|? ) : ('a, int) exec

  (** [!?? quip command_pattern] is a function of [command_pattern]
      parameters which behaves as [quip] but does not terminate if
      [quip command_pattern ...] returns a non-zero exit code. The
      exit code can be retrieved with [{?$} "?"]. *)
  val ( !?? ) : (string -> 'b,'b) exec -> ('a,'b) exec

  (** [!?* quip command_pattern] is a function of [command_pattern]
      parameters which behaves as [quip] but does not terminate if
      [quip command_pattern ...] returns a non-zero exit code. The
      exit code is the second element of the returned pair. *)
  val ( !?* ) : (string -> 'b,'b) exec -> ('a,'b * int) exec

  (** [?$ ENV_VAR] looks up environment variable [ENV_VAR] like
      {!getenv_default} but terminates execution with an error if
      [ENV_VAR] is not found.

      - [?$ "@"] is this program's arguments.
      - [?$ "?"] is the last subprocess's exit code.
  *)
  val ( ?$ ) : string -> string
end

include module type of Quips

(** [export ENV_VAR value] exports [ENV_VAR=value] for all subsequent
    executions. *)
val export : string -> string -> unit

(** [unset ENV_VAR] unsets [ENV_VAR] for all subsequent executions. *)
val unset : string -> unit

(** [set opts] sets shell options [opts] for all subsequent executions. *)
val set : string -> unit

(** [map] is {!List.map}. *)
val map : ('a -> 'b) -> 'a list -> 'b list

(** [q s] is the quoted string of [s]. *)
val q : string -> string

(** [ql sl] is {!map} {!q}. *)
val ql : string list -> string list

(** [some s] is [None] when [s] is [""] and [Some s] when [s] isn't. *)
val some : string -> string option

(** [list s] is [s] split by [' ']. *)
val list : string -> string list

(** [lines s] is [s] split by ['\n']. *)
val lines : string -> string list

(** [pair s] is [s] split by [':'] at most once. *)
val pair : string -> string * string option

(** [getenv_default ENV_VAR default] is this program's value for
    environment variable [ENV_VAR] (not including values {!export}ed)
    or [default] if no environment variable [ENV_VAR] exists. *)
val getenv_default : string -> string -> string

(** [fuzzy_bool_of_string tRuE111] is true if [tRuE111] isn't ["false"]. *)
val fuzzy_bool_of_string : string -> bool

(** [echo pattern] is a function of [pattern] parameters which prints
    [pattern ...] to standard output followed by a newline. *)
val echo : ('a, unit) exec

(** [cd dir] changes the process's current working directory to [dir]. *)
val cd : string -> unit

(** [trim s] is a copy of [s] without the leading or trailing
    whitespace characters `' '`, `'\012'`, `'\n'`, `'\r'`, or `'\t'`. *)
val trim : string -> string
