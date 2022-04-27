import { TezosToolkit } from "@taquito/taquito";
import { InMemorySigner } from "@taquito/signer";

import config from "../../config"

const networkConfig = config.networks.sandbox;

const rpc = networkConfig.rpc;
const Tezos = new TezosToolkit(rpc);

const accounts = networkConfig.accounts;


const signerAlice = new InMemorySigner(accounts.alice.sk);
const signerBob = new InMemorySigner(accounts.bob.sk);

Tezos.setSignerProvider(signerAlice);

export {
  Tezos,
  signerAlice,
  signerBob,
  accounts
};
