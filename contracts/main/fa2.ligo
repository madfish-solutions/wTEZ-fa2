#import  "../partial/errors.ligo" "Errors"
#import "../partial/fa2_consts.ligo" "Constants"
#include "../partial/utils.ligo"
#include "../partial/fa2_types.ligo"
#include "../partial/fa2_helpers.ligo"
#include "../partial/fa2_methods.ligo"


function main(
  const action          : fa2_action_t;
  const s               : fa2_storage_t)
                        : return_t is
  case action of [
  | Non_tez_use(params)         -> non_tz_main(params, s)
  | Mint(params)                -> (Constants.no_operations, make_mint(params, s))
  | Default                     -> (Constants.no_operations, s)
  ]
