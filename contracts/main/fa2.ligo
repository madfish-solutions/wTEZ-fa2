#import  "../partial/errors.ligo" "Errors"
#import "../partial/utils.ligo" "Utils"
#import "../partial/fa2_consts.ligo" "Constants"
#include "../partial/fa2_types.ligo"
#include "../partial/fa2_helpers.ligo"
#include "../partial/fa2_methods.ligo"


function main(
  const action          : fa2_action_t;
  const s               : fa2_storage_t)
                        : return_t is
  case action of [
  | Set_admin(params)         -> (Constants.no_operations, set_admin(params, s))
  | Approve_admin             -> (Constants.no_operations, approve_admin(s))
  | Transfer(params)          -> (Constants.no_operations, transfer(s, params))
  | Update_operators(params)  -> (Constants.no_operations, update_operators(s, params))
  | Balance_of(params)        -> (get_balance_of(params, s), s)
  | Update_metadata(params)   -> (Constants.no_operations, update_metadata(params, s))
  | Create_token              -> (Constants.no_operations, create_token(s))
  | Mint(params)              -> (Constants.no_operations, make_mint(params, s))
  | Burn(params)              -> burn(params, s)
  | Set_delegate(params)      -> delegate(params, s)
  | Get_baking_rewards(params)-> get_baking_rewards(params, s)
  | Default                   -> (Constants.no_operations, s)
  ]
