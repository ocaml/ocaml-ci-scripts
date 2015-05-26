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

(* Brevity is the soul of wit. *)

type ('a,'b) exec = ('a, unit, string, 'b) format4 -> 'a

let env = Hashtbl.create 8
let shell_set = ref ""
let suppress_failure = ref false
let last_status = ref 0

let export k v = Hashtbl.replace env k (Some v)

let set opts = shell_set := opts

let unset k = Hashtbl.replace env k None

let getenv_default var default = try Sys.getenv var with Not_found -> default

let map = List.map

let q = Printf.sprintf "\"%s\""

let ql = map q

(* Not tail recursive for "performance", please choose low values for
   [max]. The idea is that max is always small because it's hard
   code *)
let split_char_bounded str ~on ~max =
  let open String in
  if str = "" then []
  else if max = 1 then [str]
  else
    let rec loop offset tokens =
      if tokens = max - 1
      then [sub str offset (length str - offset)]
      else
        try
          let index = index_from str offset on in
          if index = offset then
            ""::(loop (offset + 1) (tokens + 1))
          else
            let token = String.sub str offset (index - offset) in
            token::(loop (index + 1) (tokens + 1))
        with Not_found -> [sub str offset (length str - offset)]
    in loop 0 0

let split_char_unbounded_no_trailer str ~on =
  let open String in
  if str = "" then []
  else
    let rec loop acc offset =
      try begin
        let index = rindex_from str offset on in
        if index = offset then
          (*loop (""::acc) (index - 1) -- no_trailer modified *)
          loop acc (index - 1)
        else
          let token = sub str (index + 1) (offset - index) in
          loop (token::acc) (index - 1)
      end
      with Not_found -> (sub str 0 (offset + 1))::acc
    in loop [] (length str - 1)

let some = function "" -> None | x -> Some x
let list = split_char_unbounded_no_trailer ~on:' '
let lines = split_char_unbounded_no_trailer ~on:'\n'
let pair s = match split_char_bounded s ~on:':' ~max:2 with
  | []      -> ("",None)
  | [x]     -> (x, None)
  | x::y::_ -> (x, Some y)

let fuzzy_bool_of_string s = match String.lowercase s with
  | "false" | "0" -> false
  | _ -> true

let echo fmt = Printf.ksprintf print_endline fmt

let cd = Unix.chdir

let is_space = function ' ' | '\012' | '\n' | '\r' | '\t' -> true | _ -> false

let trim s =
  let open String in
  let len = length s in
  let i = ref 0 in
  while !i < len && is_space (unsafe_get s !i) do incr i done;
  let j = ref (len - 1) in
  while !j >= !i && is_space (unsafe_get s !j) do decr j done;
  if !j >= !i
  then sub s !i (!j - !i + 1)
  else ""

let same_fds f = Unix.(f ~stdin ~stdout ~stderr)

let shell command ~stdin ~stdout ~stderr =
  Unix.create_process "sh" [|"sh";"-c";command|] stdin stdout stderr

let after pid = Unix.(match waitpid [] pid with
  | (_,WEXITED k) -> last_status := k; k
  | (_,WSIGNALED _) -> failwith "child unexpectedly signaled"
  | (_,WSTOPPED _) -> failwith "child unexpectedly stopped"
)

let after_shell command ~stdin ~stdout ~stderr =
  match after (shell command ~stdin ~stdout ~stderr) with
  | 0 -> ()
  | x ->
    if not !suppress_failure
    then begin
      Printf.eprintf "'%s' exited %d. Terminating with %d\n" command x x;
      exit x
    end

module Quips = struct
  let ( *~ ) list sep = String.concat sep list

  let (~~) = format_of_string

  let apply_env command =
    let set = match !shell_set with
      | "" -> " "
      | opts -> " set "^opts^"; "
    in
    ((Hashtbl.fold (fun k v list -> match v with
       | Some v -> (k^"="^v^" export "^k^";")::list
       | None -> ("unset "^k^";")::list
     ) env []) *~ " ") ^ set ^ command

  let (?| ) command = same_fds (after_shell (apply_env command))

  let (?|.) fmt = Printf.ksprintf (?|) fmt

  let (?|~) fmt = Printf.ksprintf (fun command ->
    print_endline command;
    ?|  command
  ) fmt

  let (?|>) fmt = Printf.ksprintf (fun command ->
    let buf = Buffer.create (5*80) in
    let rstdout, stdout = Unix.pipe () in
    Unix.set_close_on_exec rstdout;
    let stdin = Unix.stdin in
    let stderr = Unix.stderr in
    after_shell (apply_env command) ~stdin ~stdout ~stderr;
    Unix.close stdout;
    let stdout = Unix.in_channel_of_descr rstdout in
    try while true do Buffer.add_channel buf stdout 1 done; ""
    with End_of_file -> close_in stdout; Buffer.contents buf
  ) fmt

  let (!??) (quip:('a,'b) exec) fmt = Printf.ksprintf (fun command ->
    suppress_failure := true;
    let r = quip "%s" command in
    suppress_failure := false;
    r
  ) fmt

  let (!?*) quip fmt = Printf.ksprintf (fun command ->
    let r = !?? quip "%s" command in
    r, !last_status
  ) fmt

  let (?|?) fmt = Printf.ksprintf (fun command ->
    !?? (?|.) "%s" command;
    !last_status
  ) fmt

  let (?$) = function
    | "@" -> List.(ql (tl (Array.to_list Sys.argv))) *~ " "
    | "?" -> string_of_int !last_status
    | v -> match some (getenv_default v "") with
      | Some v -> v
      | None ->
        Printf.eprintf "I don't know what variable '%s' means and I give up.\n" v;
        exit 1
end

include Quips
