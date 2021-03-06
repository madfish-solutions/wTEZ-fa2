import { accounts } from "../utils/cli";
import { MichelsonMap } from "@taquito/taquito";
import {
  AccountInfo,
  KeyHashString,
  TokenMetadata,
  TokenStorage,
} from "../../API/types";
import { BytesString, TezosAddress } from "../../utils/helpers";
import BigNumber from "bignumber.js";

const metadata = MichelsonMap.fromLiteral({
  "": Buffer.from("tezos-storage:metadata", "ascii").toString("hex"),
  metadata: Buffer.from(
    JSON.stringify({
      name: "Wrapped Tez",
      version: "v1.0.0",
      description: "Wrapped Tezos FA2",
    }),
    "ascii"
  ).toString("hex"),
}) as MichelsonMap<string, BytesString>;

const testStorage: TokenStorage = {
  admin: accounts.alice.pkh as TezosAddress,
  pending_admin: null as TezosAddress,
  token_count: 1,
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
        thumbnailUri: Buffer.from(
          "https://www.vhv.rs/dpng/d/523-5236354_tezos-pre-launch-xtz-icon-tezos-logo-hd.png"
        ).toString("hex"),
      }),
    },
  }) as MichelsonMap<BigNumber.Value, TokenMetadata>,
  metadata,
  token_info: MichelsonMap.fromLiteral({
    0: 0,
  }) as MichelsonMap<BigNumber.Value, BigNumber.Value>,
  operators: MichelsonMap.fromLiteral({}) as MichelsonMap<
    TezosAddress,
    TezosAddress[]
  >,
  ledger: MichelsonMap.fromLiteral({}) as MichelsonMap<
    TezosAddress,
    BigNumber.Value
  >,
  current_delegate: null as KeyHashString,
};

export default testStorage;
