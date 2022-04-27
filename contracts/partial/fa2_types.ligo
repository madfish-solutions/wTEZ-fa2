
type token_id is nat

type token_metadata_info is [@layout:comb] record [
  token_id      : token_id;
  token_info    : map(string, bytes);
]

type transfer_destination is [@layout:comb] record [
  to_           : address;
  token_id      : token_id;
  amount        : nat;
]

type transfer_param is [@layout:comb] record [
  from_         : address;
  txs           : list(transfer_destination);
]

type transfer_params is list(transfer_param)

type balance_of_request is [@layout:comb] record [
  owner         : address;
  token_id      : token_id;
]

type balance_of_response is [@layout:comb] record [
  request       : balance_of_request;
  balance       : nat;
]

type balance_params is [@layout:comb] record [
  requests      : list(balance_of_request);
  callback      : contract(list(balance_of_response));
]

type operator_param is [@layout:comb] record [
  owner         : address;
  operator      : address;
  token_id      : token_id;
]

type update_operator_param is
| Add_operator        of operator_param
| Remove_operator     of operator_param

type update_operator_params is list(update_operator_param)

type token_meta_info_t    is [@layout:comb] record [
  token_id                : nat;
  token_info              : map(string, bytes);
]

type upd_meta_param_t     is token_meta_info_t

type account is [@layout:comb] record [
  updated             : timestamp;
  permits             : set(address);
]

type token_info is [@layout:comb] record [
  total_supply        : nat;
]

type fa2_storage is [@layout:comb] record [
  ledger              : big_map(address, nat);
  account_info        : big_map(address, account);
  token_info          : big_map(token_id, token_info);
  metadata            : big_map(string, bytes);
  token_metadata      : big_map(token_id, token_metadata_info);
  admin               : address;
  pending_admin       : option(address);
  last_token_id       : nat;
  current_delegate    : option(key_hash);
]

type return is list (operation) * fa2_storage

type asset_param        is [@layout:comb] record [
    receiver              : address;
    amount                : nat;
  ]

type burn_param        is [@layout:comb] record [
    from_                 : address;
    receiver              : address;
    amount                : nat;
  ]

type fa2_action is
| Transfer                of transfer_params
| Balance_of              of balance_params
| Update_operators        of update_operator_params
| Update_metadata         of upd_meta_param_t
| Set_admin               of address
| Approve_admin           of unit
| Create_token            of unit
| Mint                    of asset_param
| Burn                    of burn_param
| Set_delegate            of option(key_hash)
| Default                 of unit // also Mint