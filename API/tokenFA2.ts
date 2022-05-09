/* eslint-disable @typescript-eslint/no-explicit-any */
import { Contract, MichelsonMap, TezosToolkit } from "@taquito/taquito";
import { TransactionOperation } from "@taquito/taquito/dist/types/operations/transaction-operation";
const defaultTokenId = 0;
import BigNumber from "bignumber.js";
import { KeyHashString, TokenMetadata, TokenStorage } from "./types";
import {
  BytesString,
  prepareProviderOptions,
  TezosAddress,
} from "../utils/helpers";
import { confirmOperation } from "../utils/confirmation";

export class SingleTokenFA2 {
  public contract: Contract;
  public storage: TokenStorage;
  readonly Tezos: TezosToolkit;

  constructor(tezos: TezosToolkit, contract: Contract) {
    this.Tezos = tezos;
    this.contract = contract;
  }

  static async init(
    tezos: TezosToolkit,
    tokenAddress: TezosAddress
  ): Promise<SingleTokenFA2> {
    return new SingleTokenFA2(tezos, await tezos.contract.at(tokenAddress));
  }

  async updateProvider(accountName: string): Promise<void> {
    const config = await prepareProviderOptions(accountName);
    this.Tezos.setProvider(config);
  }

  async updateStorage(): Promise<void> {
    this.storage = (await this.contract.storage()) as TokenStorage;
  }

  async transfer(
    from: TezosAddress,
    to: TezosAddress,
    amount: BigNumber.Value,
    tokenId: BigNumber.Value = defaultTokenId
  ): Promise<TransactionOperation> {
    const operation = await this.contract.methods
      .transfer([
        {
          from_: from,
          txs: [
            {
              token_id: tokenId,
              amount: amount,
              to_: to,
            },
          ],
        },
      ])
      .send();

    await confirmOperation(this.Tezos, operation.hash);
    return operation;
  }

  async approve(
    to: TezosAddress,
    amount: BigNumber.Value,
    tokenId: BigNumber.Value = defaultTokenId
  ): Promise<TransactionOperation> {
    return await this.updateOperators([
      {
        option: new BigNumber(amount).eq(0)
          ? "remove_operator"
          : "add_operator",
        param: {
          owner: await this.Tezos.signer.publicKeyHash(),
          operator: to,
          token_id: tokenId,
        },
      },
    ]);
  }

  async mint(
    amount: BigNumber.Value,
    receiver: TezosAddress
  ): Promise<TransactionOperation> {
    const operation = await this.contract.methodsObject
      .mint(receiver)
      .send({ amount: new BigNumber(amount).shiftedBy(-6).toNumber() });
    await confirmOperation(this.Tezos, operation.hash);
    return operation;
  }

  async burn(
    from: TezosAddress,
    amount: BigNumber.Value,
    receiver: TezosAddress
  ): Promise<TransactionOperation> {
    const operation = await this.contract.methodsObject
      .burn({
        from_: from,
        amount,
        receiver,
      })
      .send();
    await confirmOperation(this.Tezos, operation.hash);
    return operation;
  }

  async set_delegate(
    delegate: KeyHashString | null
  ): Promise<TransactionOperation> {
    const operation = await this.contract.methods.set_delegate(delegate).send();
    await confirmOperation(this.Tezos, operation.hash);
    return operation;
  }

  async get_baking_rewards(receiver: TezosAddress) {
    const operation = await this.contract.methods
      .get_baking_rewards(receiver)
      .send();
    await confirmOperation(this.Tezos, operation.hash);
    return operation;
  }

  async set_admin(admin: TezosAddress): Promise<TransactionOperation> {
    const operation = await this.contract.methods.set_admin(admin).send();
    await confirmOperation(this.Tezos, operation.hash);
    return operation;
  }

  async approve_admin(): Promise<TransactionOperation> {
    const operation = await this.contract.methods.approve_admin().send();
    await confirmOperation(this.Tezos, operation.hash);
    return operation;
  }

  async create_token(
    metadata: MichelsonMap<string, BytesString>
  ): Promise<TransactionOperation> {
    const operation = await this.contract.methods.create_token(metadata).send();
    await confirmOperation(this.Tezos, operation.hash);
    return operation;
  }

  async balanceOf(
    requests: {
      owner: TezosAddress;
      token_id: BigNumber.Value;
    }[],
    contract: string
  ): Promise<TransactionOperation> {
    const operation = await this.contract.methods
      .balance_of({ requests, contract })
      .send();
    await confirmOperation(this.Tezos, operation.hash);
    return operation;
  }

  async updateOperators(
    params: {
      option: "add_operator" | "remove_operator";
      param: {
        owner: TezosAddress;
        operator: TezosAddress;
        token_id: BigNumber.Value;
      };
    }[]
  ): Promise<TransactionOperation> {
    const operation = await this.contract.methods
      .update_operators(
        params.map((param) => {
          return {
            [param.option]: param.param,
          };
        })
      )
      .send();
    await confirmOperation(this.Tezos, operation.hash);
    return operation;
  }
}
