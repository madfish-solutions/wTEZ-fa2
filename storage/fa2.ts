import { MichelsonMap } from "@taquito/taquito";
import { TezosAddress } from "../utils/helpers";

const metadata = MichelsonMap.fromLiteral({
  "": Buffer.from("tezos-storage:wTez", "ascii").toString("hex"),
  wTez: Buffer.from(
    JSON.stringify({
      name: "Wrapped Tez",
      version: "v1.0.0",
      description: "Wrapped Tezos FA2.",
    }),
    "ascii"
  ).toString("hex"),
});

export default {
  admin: null as TezosAddress,
  pending_admin: null as TezosAddress,
  last_token_id: 1,
  token_metadata: MichelsonMap.fromLiteral({
    0: {
      token_id: 0,
      token_info: MichelsonMap.fromLiteral({
        symbol: Buffer.from("wTEZ").toString("hex"),
        name: Buffer.from("Wrapped Tezos FA2 token").toString("hex"),
        decimals: Buffer.from("6").toString("hex"),
        is_transferable: Buffer.from("true").toString("hex"),
        is_boolean_amount: Buffer.from("false").toString("hex"),
        should_prefer_symbol: Buffer.from("false").toString("hex"),
        thumbnailUri: Buffer.from("https://www.vhv.rs/dpng/d/523-5236354_tezos-pre-launch-xtz-icon-tezos-logo-hd.png").toString("hex"),
      })
    }
  }),
  metadata,
  token_info: MichelsonMap.fromLiteral({
    0: 0
  }),
  account_info: MichelsonMap.fromLiteral({})
};
