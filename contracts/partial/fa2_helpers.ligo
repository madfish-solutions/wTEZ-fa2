
(* Helper function to get account *)
function get_account(const user : address; const s : fa2_storage) : account is
  case s.account_info[user] of [
  | None -> record [
    updated         = Tezos.now;
    permits         = (set [] : set(address));
  ]
  | Some(v) -> v
  ]

function set_account(
  const user            : address;
  const account         : account;
  const account_info    : big_map(address, account))
                        : big_map(address, account) is
  Big_map.update(
    user,
    Some(
      account with record [
        updated         = Tezos.now
      ]
    ),
    account_info
  )

(* Helper function to get token info *)
function get_token_info(const token_id : token_id; const s : fa2_storage) : token_info is
  case s.token_info[token_id] of [
  | None -> record [
    total_supply    = 0n;
  ]
  | Some(v) -> v
  ]

(* Helper function to get acount balance by token *)
function get_balance(const user : address; const ledger : big_map(address, nat)) : nat is
  case ledger[user] of [
  | None -> 0n
  | Some(v) -> v
  ]

function set_balance(
  const user          : address; 
  const value         : nat; 
  const ledger        : big_map(address, nat)) 
                      : big_map(address, nat) is
  Big_map.update(
    user,
    Some(value),
    ledger
  )
function require(
  const param           : bool;
  const error           : string)
                        : unit is
  assert_with_error(param, error)

function get_nat_or_fail(
  const value           : int;
  const error           : string)
                        : nat is
  case is_nat(value) of [
  | Some(natural) -> natural
  | None -> (failwith(error): nat)
  ]

function unwrap<a>(
  const param           : option(a);
  const error           : string)
                        : a is
  case param of [
  | Some(instance) -> instance
  | None -> failwith(error)
  ]
