module FA2 is {
  const not_operator    : string = "FA2_NOT_OPERATOR";
  const undefined       : string = "FA2_TOKEN_UNDEFINED";
  const not_owner       : string = "FA2_NOT_OWNER";
  const low_balance     : string = "FA2_INSUFFICIENT_BALANCE";
  const not_admin       : string = "FA2_NOT_ADMIN";
  const wrong_contract  : string = "NOT_FA2_CONTRACT";
}

module WrappedTezos is {
  const single          : string = "FA2_SINGLE_ASSET";
  const empty_candidate : string = "FA2_NO_ADMIN_CANDIDATE";
  const not_for_tez     : string = "NOT_TEZOS_RECEIVER";
  const zero_mint       : string = "FA2_ZERO_MINT";
  const low_rewards     : string = "LOW_TEZOS_REWARD";
}