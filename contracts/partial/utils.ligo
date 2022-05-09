[@inline] function require(
  const param           : bool;
  const error           : string)
                        : unit is
  assert_with_error(param, error)

[@inline] function get_nat_or_fail(
  const value           : int;
  const error           : string)
                        : nat is
  case is_nat(value) of [
  | Some(natural) -> natural
  | None -> (failwith(error): nat)
  ]

[@inline] function unwrap<a>(
  const param           : option(a);
  const error           : string)
                        : a is
  case param of [
  | Some(instance) -> instance
  | None -> failwith(error)
  ]

[@inline] function unwrap_or<a>(
  const param           : option(a);
  const default         : a)
                        : a is
  case param of [
  | Some(instance) -> instance
  | None -> default
  ]

[@inline] function to_mutez(const number: nat) : tez is number * 1mutez;
[@inline] function from_mutez(const value: tez) : nat is value / 1mutez;