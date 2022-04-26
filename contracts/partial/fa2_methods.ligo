
(* Perform transfers *)
function iterate_transfer(const s : fa2_storage; const params : transfer_param) : fa2_storage is
  block {
    (* Perform single transfer *)
    function make_transfer(var s : fa2_storage; const transfer_dst : transfer_destination) : fa2_storage is
      block {
        (* Create or get source account *)
        var src_account : account := get_account(params.from_, s);

        (* Check permissions *)
        require(params.from_ = Tezos.sender or src_account.permits contains Tezos.sender, Errors.FA2.notOperator);


        // (* Token id check *)
        require(transfer_dst.token_id < s.last_token_id, Errors.FA2.undefined);


        (* Get source balance *)
        const src_balance : nat = get_balance_by_token(src_account, transfer_dst.token_id);

        (* Balance check *)
        (* Update source balance *)
        src_account.balances[transfer_dst.token_id] := get_nat_or_fail(
          src_balance - transfer_dst.amount,
          Errors.FA2.lowBalance
        );

        (* Update storage *)
        s.account_info := set_account(params.from_, src_account, s.account_info);

        (* Create or get destination account *)
        var dst_account : account := get_account(transfer_dst.to_, s);

        (* Get receiver balance *)
        const dst_balance : nat = get_balance_by_token(dst_account, transfer_dst.token_id);

        (* Update destination balance *)
        dst_account.balances[transfer_dst.token_id] := dst_balance + transfer_dst.amount;

        (* Update storage *)
        s.account_info := set_account(transfer_dst.to_, dst_account, s.account_info);
    } with s
} with List.fold(make_transfer, params.txs, s)

(* Perform single operator update *)
function iterate_update_operators(var s : fa2_storage; const params : update_operator_param) : fa2_storage is
  block {
    case params of [
    | Add_operator(param) -> block {
      (* Check an owner *)
      require(Tezos.sender = param.owner, Errors.FA2.notOwner);

      (* Create or get source account *)
      var src_account : account := get_account(param.owner, s);

      (* Add operator *)
      src_account.permits := Set.add(param.operator, src_account.permits);

      (* Update storage *)
      s.account_info := set_account(param.owner, src_account, s.account_info);
    }
    | Remove_operator(param) -> block {
      (* Check an owner *)
      require(Tezos.sender = param.owner, Errors.FA2.notOwner);

      (* Create or get source account *)
      var src_account : account := get_account(param.owner, s);

      (* Remove operator *)
      src_account.permits := Set.remove(param.operator, src_account.permits);

      (* Update storage *)
      s.account_info := set_account(param.owner, src_account, s.account_info);
    }
    ]
  } with s

(* Perform balance lookup *)
function get_balance_of(const balance_params : balance_params; const s : fa2_storage) : list(operation) is
  block {
    (* Perform single balance lookup *)
    function look_up_balance(const l: list(balance_of_response); const request : balance_of_request) : list(balance_of_response) is
      block {
        (* Retrieve the asked account from the storage *)
        const user : account = get_account(request.owner, s);

        (* Form the response *)
        var response : balance_of_response := record [
          request = request;
          balance = get_balance_by_token(user, request.token_id);
        ];
      } with response # l;

    (* Collect balances info *)
    const accumulated_response : list(balance_of_response) = List.fold(look_up_balance, balance_params.requests, (nil: list(balance_of_response)));
  } with list [Tezos.transaction(
    accumulated_response,
    0tz,
    balance_params.callback
  )]

function update_operators(const s : fa2_storage; const params : update_operator_params) : fa2_storage is
  List.fold(iterate_update_operators, params, s)

function transfer(const s : fa2_storage; const params : transfer_params) : fa2_storage is
  List.fold(iterate_transfer, params, s)

(* Perform minting new tokens *)
function make_mint(
  const param       : asset_param;
  var s             : fa2_storage)
                    : fa2_storage is
  block {
    require(Tezos.amount > 0mutez, "zero-mint");
    require(param.amount = Tezos.amount/1mutez, "wrong-TEZ-amount");

    (* Get receiver account *)
    var dst_account : account := get_account(param.receiver, s);

    (* Get receiver initial balance *)
    const dst_balance : nat =
      get_balance_by_token(dst_account, 0n);

    (* Mint new tokens *)
    dst_account.balances[0n] := dst_balance + param.amount;

    (* Get token info *)
    var token : token_info := get_token_info(0n, s);

    (* Update token total supply *)
    token.total_supply := token.total_supply + param.amount;

    (* Update storage *)
    s.account_info := set_account(param.receiver, dst_account, s.account_info);
    s.token_info[0n] := token;
  } with s

function burn(
  const param       : burn_param;
  var s             : fa2_storage)
                    : return is
  block {
    (* Get sender account *)
    var src_account : account := get_account(param.from_, s);

    require(param.from_ = Tezos.sender or src_account.permits contains Tezos.sender, Errors.FA2.notOperator);


    (* Get receiver initial balance *)
    const src_balance : nat =
      get_balance_by_token(src_account, 0n);

    (* Burn tokens *)
    src_account.balances[0n] := get_nat_or_fail(src_balance - param.amount, Errors.FA2.lowBalance);

    (* Get token info *)
    var token : token_info := get_token_info(0n, s);

    (* Update token total supply *)
    token.total_supply := get_nat_or_fail(token.total_supply - param.amount, Errors.FA2.lowBalance);

    (* Update storage *)
    s.account_info := set_account(param.from_, src_account, s.account_info);
    s.token_info[0n] := token;
    const operations = list[
      Tezos.transaction(
        Unit,
        param.amount * 1mutez,
        (Tezos.get_contract_with_error(param.receiver, "Non-Tez-receiver"): contract(unit))
      )
    ]
  } with (operations, s)

function create_token(var s : fa2_storage)
                            : fa2_storage is
  block {
    require(s.last_token_id < 1n, "Single-asset-FA2");
    require(s.admin = Tezos.sender, Errors.FA2.notAdmin);

    s.token_metadata[s.last_token_id] := record [
      token_id = s.last_token_id;
      token_info = wTez_metadata;
    ];
    s.last_token_id := s.last_token_id + 1n;
  } with s

function update_metadata(
    const params        : upd_meta_param_t;
    var   s             : fa2_storage)
                        : fa2_storage is
  block {
    require(s.admin = Tezos.sender, Errors.FA2.notAdmin);
    s.token_metadata[params.token_id] := params;
  } with s

function delegate(
  const new_delegate    : option(key_hash);
  var s                 : fa2_storage)
                        : return is
  block {
    require(s.admin = Tezos.sender, Errors.FA2.notAdmin);
  } with (
    list[
      Tezos.set_delegate(new_delegate)
    ],
    s with record[
      current_delegate = new_delegate
    ]
  )

