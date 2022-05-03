(* Perform balance lookup *)
function get_balance_of(
  const balance_params  : balance_params_t;
  const s               : fa2_storage_t)
                        : list(operation) is
  block {
    (* Perform single balance lookup *)
    function look_up_balance(const l: list(balance_of_response_t); const request : balance_of_request_t) : list(balance_of_response_t) is
      block {
        (* Form the response *)
        var response : balance_of_response_t := record [
          request = request;
          balance = get_balance(request.owner, s.ledger);
        ];
      } with response # l;

    (* Collect balances info *)
    const accumulated_response : list(balance_of_response_t) = List.fold(look_up_balance, balance_params.requests, (nil: list(balance_of_response_t)));
  } with list [Tezos.transaction(
    accumulated_response,
    0tz,
    balance_params.callback
  )]

function update_operators(
  const s               : fa2_storage_t;
  const params          : update_operator_params_t)
                        : fa2_storage_t is
  List.fold(iterate_update_operators, params, s)

function transfer(
  const s               : fa2_storage_t;
  const params          : transfer_params_t)
                        : fa2_storage_t is
  List.fold(iterate_transfer, params, s)

(* Perform minting new tokens *)
function make_mint(
  const receiver        : address;
  var s                 : fa2_storage_t)
                        : fa2_storage_t is
  block {
    Utils.require(Tezos.amount > 0mutez, Errors.WrappedTezos.zero_mint);
    const value = Utils.from_mutez(Tezos.amount);

    (* Get receiver account *)
    var dst_account : account_t := get_account(receiver, s.account_info);

    (* Get receiver initial balance *)
    const dst_balance : nat =
      get_balance(receiver, s.ledger);

    (* Mint new tokens *)
    s.ledger := set_balance(
      receiver,
      dst_balance + value,
      s.ledger);

    (* Get token info *)
    var token : token_info_t := get_token_info(0n, s.token_info);

    (* Update token total supply *)
    token.total_supply := token.total_supply + value;

    (* Update storage *)
    s.account_info := set_account(receiver, dst_account, s.account_info);
    s.token_info[0n] := token;
  } with s

function burn(
  const param           : burn_param_t;
  var s                 : fa2_storage_t)
                        : return_t is
  block {
    (* Get sender account *)
    var src_account : account_t := get_account(param.from_, s.account_info);

    Utils.require(param.from_ = Tezos.sender or src_account.operators contains Tezos.sender, Errors.FA2.not_operator);


    (* Get receiver initial balance *)
    const src_balance : nat = get_balance(param.from_, s.ledger);

    (* Burn tokens *)
    s.ledger := set_balance(
      param.from_,
      Utils.get_nat_or_fail(src_balance - param.amount, Errors.FA2.low_balance),
      s.ledger);

    (* Get token info *)
    var token : token_info_t := get_token_info(0n, s.token_info);

    (* Update token total supply *)
    token.total_supply := Utils.get_nat_or_fail(token.total_supply - param.amount, Errors.FA2.low_balance);

    (* Update storage *)
    s.account_info := set_account(param.from_, src_account, s.account_info);
    s.token_info[0n] := token;
    const operations = list[
      Tezos.transaction(
        Unit,
        Utils.to_mutez(param.amount),
        (Tezos.get_contract_with_error(param.receiver, Errors.WrappedTezos.not_for_tez): contract(unit))
      )
    ]
  } with (operations, s)

function get_baking_rewards(
  const receiver        : address;
  const s               : fa2_storage_t)
                        : return_t is
  block {
    Utils.require(s.admin = Tezos.sender, Errors.FA2.not_admin);
    const token : token_info_t = get_token_info(0n, s.token_info);
    const rewards = Utils.unwrap(Tezos.balance - Utils.to_mutez(token.total_supply), Errors.WrappedTezos.low_rewards);
    const operations = list[
      Tezos.transaction(
        Unit,
        rewards,
        (Tezos.get_contract_with_error(receiver, Errors.WrappedTezos.not_for_tez): contract(unit))
      )
    ]
  } with (operations, s)

function create_token(
  var s                 : fa2_storage_t)
                        : fa2_storage_t is
  block {
    Utils.require(s.token_count < 1n, Errors.WrappedTezos.single);
    Utils.require(s.admin = Tezos.sender, Errors.FA2.not_admin);

    s.token_metadata[s.token_count] := record [
      token_id = s.token_count;
      token_info = Constants.wTez_metadata;
    ];
    s.token_count := s.token_count + 1n;
  } with s

function update_metadata(
    const params        : upd_meta_param_t;
    var   s             : fa2_storage_t)
                        : fa2_storage_t is
  block {
    Utils.require(s.admin = Tezos.sender, Errors.FA2.not_admin);
    s.token_metadata[params.token_id] := params;
  } with s

function delegate(
  const new_delegate    : option(key_hash);
  var s                 : fa2_storage_t)
                        : return_t is
  block {
    Utils.require(s.admin = Tezos.sender, Errors.FA2.not_admin);
  } with (
    list[
      Tezos.set_delegate(new_delegate)
    ],
    s with record[
      current_delegate = new_delegate
    ]
  )


function set_admin(
  const new_admin        : address;
  const s               : fa2_storage_t)
                        : fa2_storage_t is
  block {
    Utils.require(s.admin = Tezos.sender, Errors.FA2.not_admin);
  } with s with record[ pending_admin = Some(new_admin) ]

function approve_admin(
  var s                 : fa2_storage_t)
                        : fa2_storage_t is
  block {
    const pending_admin = Utils.unwrap(s.pending_admin, Errors.WrappedTezos.empty_candidate);
    Utils.require(Tezos.sender = pending_admin or Tezos.sender = s.admin, Errors.FA2.not_admin);
    s.admin := Tezos.sender;
    s.pending_admin := (None : option(address));
  } with s

