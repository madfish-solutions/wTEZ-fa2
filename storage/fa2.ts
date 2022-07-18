import { MichelsonMap } from "@taquito/taquito";
import { KeyHashString, TokenMetadata, TokenStorage } from "../API/types";
import { accounts } from "../utils/constants";
import { BytesString, TezosAddress } from "../utils/helpers";
import BigNumber from "bignumber.js";

const tokenMetadata = MichelsonMap.fromLiteral({
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
        "ipfs://QmUWhCYXtC8r8aXgjrwsLrZmopiGMHdLWoQzEueAktJbHB"
      ).toString("hex"),
    }),
  },
}) as MichelsonMap<BigNumber.Value, TokenMetadata>;

const metadata = MichelsonMap.fromLiteral({
  "": Buffer.from(
    "ipfs://Qmej4GUjbvo6aa4qvRFrBF7TCYKZLL4SDPQGod6hXBPu1x",
    "ascii"
  ).toString("hex"),
  // metadata: Buffer.from(
  //   JSON.stringify({
  //     name: "Wrapped Tez",
  //     version: "v1.0.3",
  //     description: "Wrapped Tezos FA2",
  //     authors: ["Madfish.Solutions <https://www.madfish.solutions>"],
  //     source: {
  //       tools: ["Ligo", "Flextesa"],
  //       location:
  //         "https://github.com/madfish-solutions/wTEZ-fa2/blob/v1.0.3/contracts/main/fa2.ligo",
  //     },
  //     interfaces: ["TZIP-012 git 1728fcfe", "TZIP-016"],
  //   }),
  //   "ascii"
  // ).toString("hex"),
}) as MichelsonMap<string, BytesString>;

const storage: TokenStorage = {
  admin: accounts.alice.pkh as TezosAddress,
  pending_admin: null as TezosAddress,
  token_count: 1,
  token_metadata: tokenMetadata,
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

export default storage;
