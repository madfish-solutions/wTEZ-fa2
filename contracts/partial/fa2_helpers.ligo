(* Perform transfers *)
function iterate_transfer(
  const s               : fa2_storage_t;
  const params          : transfer_param_t)
                        : fa2_storage_t is
  block {
    const src_operators : set(address) = unwrap_or(s.operators[params.from_], (set [] : set(address)));
    require(params.from_ = Tezos.sender or src_operators contains Tezos.sender, Errors.FA2.not_operator);
    function make_transfer(var s : fa2_storage_t; const transfer_dst : transfer_destination_t) : fa2_storage_t is
      block {
        // (* Token id check *)
        require(transfer_dst.token_id < s.token_count, Errors.FA2.undefined);

        (* Update source balance *)
        s.ledger[params.from_] := get_nat_or_fail(
          unwrap_or(s.ledger[params.from_], 0n) - transfer_dst.amount,
          Errors.FA2.low_balance
        );
        (* Update destination balance *)
        s.ledger[transfer_dst.to_] := unwrap_or(s.ledger[transfer_dst.to_], 0n) + transfer_dst.amount;
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

    require(param.token_id < s.token_count, Errors.FA2.undefined);
    require(Tezos.sender = param.owner, Errors.FA2.not_owner);

		var src_operators : set(address) :=  unwrap_or(s.operators[param.owner], (set [] : set(address)));

    src_operators := Set.update(param.operator, should_add, src_operators);

    s.operators[param.owner] := src_operators;
  } with s
