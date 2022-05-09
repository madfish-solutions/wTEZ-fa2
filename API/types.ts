import BigNumber from "bignumber.js";
import { MichelsonMap } from "@taquito/taquito";
import { validateKeyHash } from "@taquito/utils";
import { BytesString, TezosAddress } from "../utils/helpers";

export class KeyHashString extends String {
  constructor(value: any) {
    switch (validateKeyHash(value)) {
      case 0:
        throw new Error("NO_PREFIX_MATCHED");
      case 1:
        throw new Error("INVALID_CHECKSUM");
      case 2:
        throw new Error("INVALID_LENGTH");
      case 3:
        super(value.toString());
        return this;
    }
  }
}

export declare type AccountInfo = {
  updated: Date;
  operators: TezosAddress[];
};

export declare type TokenMetadata = {
  token_id: BigNumber.Value;
  token_info: MichelsonMap<string, BytesString>;
};

export declare type TokenStorage = {
  ledger: MichelsonMap<TezosAddress, BigNumber.Value>;
  account_info: MichelsonMap<TezosAddress, AccountInfo>;
  token_info: MichelsonMap<BigNumber.Value, BigNumber.Value>;
  metadata: MichelsonMap<string, BytesString>;
  token_metadata: MichelsonMap<BigNumber.Value, TokenMetadata>;
  admin: TezosAddress;
  pending_admin: TezosAddress | null;
  token_count: BigNumber.Value;
  current_delegate: KeyHashString | null;
};
