(* Helper function to get account *)
function get_account(
  const user            : address;
  const account_info    : big_map(address, account_t))
                        : account_t is
  Utils.unwrap_or(account_info[user], record [
    updated         = Tezos.now;
    operators         = (set [] : set(address));
  ]);

function set_account(
  const user            : address;
  const account         : account_t;
  const account_info    : big_map(address, account_t))
                        : big_map(address, account_t) is
  Big_map.update(
    user,
    Some(
      account with record [
        updated         = Tezos.now
      ]
    ),
    account_info
  )

(* Helper function to get acount balance by token *)
function get_balance(
  const user            : address;
  const ledger          : big_map(address, nat))
                        : nat is
  Utils.unwrap_or(ledger[user], 0n)

function set_balance(
  const user            : address;
  const value           : nat;
  const ledger          : big_map(address, nat))
                        : big_map(address, nat) is
  Big_map.update(
    user,
    Some(value),
    ledger
  )

(* Helper function to get token info *)
function get_token_info(
  const token_id        : token_id_t;
  const token_info      : big_map(token_id_t, token_info_t))
                        : token_info_t is
  Utils.unwrap_or(token_info[token_id], record [
    total_supply = 0n;
  ])

(* Perform transfers *)
function iterate_transfer(
  const s               : fa2_storage_t;
  const params          : transfer_param_t)
                        : fa2_storage_t is
  block {
    (* Perform single transfer *)
    function make_transfer(var s : fa2_storage_t; const transfer_dst : transfer_destination_t) : fa2_storage_t is
      block {
        (* Create or get source account *)
        var src_account : account_t := get_account(params.from_, s.account_info);

        (* Check permissions *)
        Utils.require(params.from_ = Tezos.sender or src_account.operators contains Tezos.sender, Errors.FA2.not_operator);


        // (* Token id check *)
        Utils.require(transfer_dst.token_id < s.token_count, Errors.FA2.undefined);


        (* Get source balance *)
        const src_balance : nat = get_balance(params.from_, s.ledger);

        (* Balance check *)
        (* Update source balance *)
        s.ledger := set_balance(
          params.from_,
          Utils.get_nat_or_fail(
            src_balance - transfer_dst.amount,
            Errors.FA2.low_balance
          ),
          s.ledger
        );

        (* Update storage *)
        s.account_info := set_account(params.from_, src_account, s.account_info);

        (* Create or get destination account *)
        var dst_account : account_t := get_account(transfer_dst.to_, s.account_info);

        (* Get receiver balance *)
        const dst_balance : nat = get_balance(transfer_dst.to_, s.ledger);

        (* Update destination balance *)
        s.ledger := set_balance(
          transfer_dst.to_,
          dst_balance + transfer_dst.amount,
          s.ledger
        );
        (* Update storage *)
        s.account_info := set_account(transfer_dst.to_, dst_account, s.account_info);
    } with s
} with List.fold(make_transfer, params.txs, s)

(* Perform single operator update *)
function iterate_update_operators(
  var s                 : fa2_storage_t;
  const params          : update_operator_param_t)
                        : fa2_storage_t is
  block {
    const (param, should_add) = case params of [
    | Add_operator(param)    -> (param, True)
    | Remove_operator(param) -> (param, False)
    ];

    Utils.require(param.token_id < s.token_count, Errors.FA2.undefined);
    Utils.require(Tezos.sender = param.owner, Errors.FA2.not_owner);

		var src_account : account_t := get_account(param.owner, s.account_info);

    src_account.operators := Set.update(param.operator, should_add, src_account.operators);

    s.account_info := set_account(param.owner, src_account, s.account_info);
  } with s
