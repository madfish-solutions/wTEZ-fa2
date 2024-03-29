(* Perform balance lookup *)
function get_balance_of(
  const balance_params  : balance_params_t;
  const s               : fa2_storage_t)
                        : list(operation) is
  block {
    (* Perform single balance lookup *)
    function look_up_balance(const l: list(balance_of_response_t); const request : balance_of_request_t) : list(balance_of_response_t) is
      block {
        require(request.token_id < s.token_count, Errors.FA2.undefined);
        (* Form the response *)
        var response : balance_of_response_t := record [
          request = request;
          balance = unwrap_or(s.ledger[request.owner], 0n);
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
    require(Tezos.amount > 0mutez, Errors.WrappedTezos.zero_mint);
    const value = from_mutez(Tezos.amount);

    (* Get receiver initial balance *)
    const dst_balance : nat = unwrap_or(s.ledger[receiver], 0n);

    (* Mint new tokens *)
    s.ledger[receiver] := dst_balance + value;

    var token : token_info_t := unwrap_or(
      s.token_info[Constants.default_token_id],
      record [
        total_supply = 0n;
      ]
    );

    (* Update token total supply *)
    token.total_supply := token.total_supply + value;

    (* Update storage *)
    s.token_info[Constants.default_token_id] := token;
  } with s

function burn(
  const param           : burn_param_t;
  var s                 : fa2_storage_t)
                        : return_t is
  block {
    (* Get spender initial balance *)
    const src_balance : nat = unwrap_or(s.ledger[param.from_], 0n);
    (* Burn tokens amount *)
    const to_burn = if param.amount = 0n then src_balance else param.amount;
    var operations := Constants.no_operations;
    if to_burn > 0n
    then {
      (* Get sender account *)
      const src_operators : set(address) =  unwrap_or(s.operators[param.from_], (set [] : set(address)));
      require(param.from_ = Tezos.sender or src_operators contains Tezos.sender, Errors.FA2.not_operator);

      s.ledger[param.from_] := get_nat_or_fail(src_balance - to_burn, Errors.FA2.low_balance);
      var token : token_info_t := unwrap_or(
        s.token_info[Constants.default_token_id],
        record [
          total_supply = 0n;
        ]
      );
      (* Update token total supply *)
      token.total_supply := get_nat_or_fail(token.total_supply - to_burn, Errors.FA2.low_balance);
      (* Update storage *)
      s.token_info[Constants.default_token_id] := token;
      operations := list[
        Tezos.transaction(
            Unit,
            to_mutez(to_burn),
            (Tezos.get_contract_with_error(param.receiver, Errors.WrappedTezos.not_for_tez): contract(unit))
          )
      ];
    }
    else skip;
  } with (operations, s)

function claim_baking_rewards(
  const receiver        : address;
  const s               : fa2_storage_t)
                        : return_t is
  block {
    require(s.admin = Tezos.sender, Errors.FA2.not_admin);
    const token : token_info_t = unwrap_or(
      s.token_info[Constants.default_token_id],
      record [
        total_supply = 0n;
      ]
    );
    const rewards = unwrap(Tezos.balance - to_mutez(token.total_supply), Errors.WrappedTezos.low_rewards);
    const operations = list[
      Tezos.transaction(
        Unit,
        rewards,
        (Tezos.get_contract_with_error(receiver, Errors.WrappedTezos.not_for_tez): contract(unit))
      )
    ]
  } with (operations, s)

function update_metadata(
    const params        : upd_meta_param_t;
    var   s             : fa2_storage_t)
                        : fa2_storage_t is
  block {
    require(s.admin = Tezos.sender, Errors.FA2.not_admin);
    s.token_metadata[Constants.default_token_id] := record[
      token_id    = Constants.default_token_id;
      token_info  = params
    ];
  } with s

function delegate(
  const new_delegate    : option(key_hash);
  var s                 : fa2_storage_t)
                        : return_t is
  block {
    require(s.admin = Tezos.sender, Errors.FA2.not_admin);
  } with (
    list[
      Tezos.set_delegate(new_delegate)
    ],
    s with record[
      current_delegate = new_delegate
    ]
  )

function set_admin(
  const new_admin       : address;
  const s               : fa2_storage_t)
                        : fa2_storage_t is
  block {
    require(s.admin = Tezos.sender, Errors.FA2.not_admin);
  } with s with record[ pending_admin = Some(new_admin) ]

function approve_admin(
  var s                 : fa2_storage_t)
                        : fa2_storage_t is
  block {
    const pending_admin = unwrap(s.pending_admin, Errors.WrappedTezos.empty_candidate);
    require(Tezos.sender = pending_admin, Errors.FA2.not_admin);
    s.admin := Tezos.sender;
    s.pending_admin := (None : option(address));
  } with s


function non_tz_main(
  const param           : non_tezos_action_t;
  const s               : fa2_storage_t)
                        : return_t is
block {
    non_tezos_call(Unit)
  } with case param of [
    // storage update only actions
    | Set_admin(params)           -> (Constants.no_operations, set_admin(params, s))
    | Approve_admin               -> (Constants.no_operations, approve_admin(s))
    | Transfer(params)            -> (Constants.no_operations, transfer(s, params))
    | Update_operators(params)    -> (Constants.no_operations, update_operators(s, params))
    | Update_metadata(params)     -> (Constants.no_operations, update_metadata(params, s))
    // callback operations only action
    | Balance_of(params)          -> (get_balance_of(params, s), s)
    // storage update and operation create actions
    | Burn(params)                -> burn(params, s)
    | Set_delegate(params)        -> delegate(params, s)
    | Claim_baking_rewards(params)-> claim_baking_rewards(params, s)
  ]