
type token_id_t         is nat

type token_metadata_info_t is [@layout:comb] record [
  token_id                : token_id_t;
  token_info              : map(string, bytes);
]

type transfer_destination_t is [@layout:comb] record [
  to_                     : address;
  token_id                : token_id_t;
  amount                  : nat;
]

type transfer_param_t   is [@layout:comb] record [
  from_                   : address;
  txs                     : list(transfer_destination_t);
]

type transfer_params_t  is list(transfer_param_t)

type balance_of_request_t is [@layout:comb] record [
  owner                   : address;
  token_id                : token_id_t;
]

type balance_of_response_t is [@layout:comb] record [
  request                 : balance_of_request_t;
  balance                 : nat;
]

type balance_params_t   is [@layout:comb] record [
  requests                : list(balance_of_request_t);
  callback                : contract(list(balance_of_response_t));
]

type operator_param_t   is [@layout:comb] record [
  owner                   : address;
  operator                : address;
  token_id                : token_id_t;
]

type update_operator_param_t is
| Add_operator            of operator_param_t
| Remove_operator         of operator_param_t

type update_operator_params_t is list(update_operator_param_t)

type token_meta_info_t  is [@layout:comb] record [
  token_id                : token_id_t;
  token_info              : map(string, bytes);
]

type upd_meta_param_t   is token_meta_info_t

type account_t          is [@layout:comb] record [
  updated                 : timestamp;
  operators               : set(address);
]

type token_info_t       is [@layout:comb] record [
  total_supply            : nat;
]

type fa2_storage_t      is [@layout:comb] record [
  ledger                  : big_map(address, nat);
  account_info            : big_map(address, account_t);
  token_info              : big_map(token_id_t, token_info_t);
  metadata                : big_map(string, bytes);
  token_metadata          : big_map(token_id_t, token_metadata_info_t);
  admin                   : address;
  pending_admin           : option(address);
  token_count             : nat;
  current_delegate        : option(key_hash);
]

type return_t           is list (operation) * fa2_storage_t

type burn_param_t       is [@layout:comb] record [
    from_                 : address;
    receiver              : address;
    amount                : nat;
  ]

type fa2_action_t       is
| Transfer                of transfer_params_t
| Balance_of              of balance_params_t
| Update_operators        of update_operator_params_t
| Update_metadata         of upd_meta_param_t
| Set_admin               of address
| Approve_admin           of unit
| Create_token            of unit
| Mint                    of address
| Burn                    of burn_param_t
| Get_baking_rewards      of address
| Set_delegate            of option(key_hash)
| Default                 of unit // for receive baking rewards