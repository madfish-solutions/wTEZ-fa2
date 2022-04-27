#import  "../partial/errors.ligo" "Errors"
#include "../partial/fa2_types.ligo"
#include "../partial/fa2_consts.ligo"
#include "../partial/fa2_helpers.ligo"
#include "../partial/fa2_methods.ligo"


function main(
  const action          : fa2_action;
  const s               : fa2_storage)
                        : return is
  case action of [
  | Set_admin(params)        -> (no_operations, set_admin(params, s))
  | Approve_admin            -> (no_operations, approve_admin(s))
  | Transfer(params)         -> (no_operations, transfer(s, params))
  | Update_operators(params) -> (no_operations, update_operators(s, params))
  | Balance_of(params)       -> (get_balance_of(params, s), s)
  | Update_metadata(params)  -> (no_operations, update_metadata(params, s))
  | Create_token             -> (no_operations, create_token(s))
  | Mint(params)             -> (no_operations, make_mint(params, s))
  | Burn(params)             -> burn(params, s)
  | Set_delegate(params)     -> delegate(params, s)
  | Default -> (
      no_operations,
      make_mint(record[
          receiver = Tezos.source;
          amount = Tezos.amount/1mutez
        ],
        s
      )
    )
  ]
