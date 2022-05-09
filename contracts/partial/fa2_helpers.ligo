(* Helper function to get account *)
[@inline] function get_operators(
  const user            : address;
  const operators    : big_map(address, set(address)))
                        : set(address) is
  Utils.unwrap_or(operators[user], (set [] : set(address)));

(* Helper function to get acount balance by token *)
[@inline] function get_balance(
  const user            : address;
  const ledger          : big_map(address, nat))
                        : nat is
  Utils.unwrap_or(ledger[user], 0n)

(* Helper function to get token info *)
[@inline] function get_token_info(
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
        var src_operators : set(address) := get_operators(params.from_, s.operators);

        (* Check permissions *)
        Utils.require(params.from_ = Tezos.sender or src_operators contains Tezos.sender, Errors.FA2.not_operator);


        // (* Token id check *)
        Utils.require(transfer_dst.token_id < s.token_count, Errors.FA2.undefined);


        (* Get source balance *)
        const src_balance : nat = get_balance(params.from_, s.ledger);

        (* Balance check *)
        (* Update source balance *)
        s.ledger[params.from_] := Utils.get_nat_or_fail(
          src_balance - transfer_dst.amount,
          Errors.FA2.low_balance
        );

        (* Update storage *)
        s.operators[params.from_] := src_operators;

        (* Create or get destination account *)
        var dst_operators : set(address) := get_operators(transfer_dst.to_, s.operators);

        (* Get receiver balance *)
        const dst_balance : nat = get_balance(transfer_dst.to_, s.ledger);

        (* Update destination balance *)
        s.ledger[transfer_dst.to_] := dst_balance + transfer_dst.amount;
        (* Update storage *)
        s.operators[transfer_dst.to_] := dst_operators;
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

		var src_operators : set(address) := get_operators(param.owner, s.operators);

    src_operators := Set.update(param.operator, should_add, src_operators);

    s.operators[param.owner] := src_operators;
  } with s
