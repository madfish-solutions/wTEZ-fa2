/* eslint-disable jest/prefer-expect-assertions */
import { Tezos, signerAlice, signerBob, accounts } from "./utils/cli";
import config from "../config";
import exampleCode from "../build/fa2.json";
import { confirmOperation } from "../utils/confirmation";
import { SingleTokenFA2 } from "../API/tokenFA2";
import testStorage from "./storage/storage";
import { TezosToolkit } from "@taquito/taquito";
import BigNumber from "bignumber.js";
import { failCase } from "../utils/helpers";

describe("wTEZ FA2 single-asset tests", () => {
  let wTEZ: SingleTokenFA2;
  let wTEZuser: SingleTokenFA2;
  const bobsTezos = new TezosToolkit(Tezos.rpc);

  beforeAll(async () => {
    try {
      Tezos.setSignerProvider(signerAlice);
      bobsTezos.setSignerProvider(signerBob);

      const deployedContract = await Tezos.contract.originate({
        storage: testStorage,
        code: exampleCode.michelson,
      });
      await confirmOperation(Tezos, deployedContract.hash);
      wTEZ = await SingleTokenFA2.init(Tezos, deployedContract.contractAddress);
      wTEZuser = await SingleTokenFA2.init(
        bobsTezos,
        deployedContract.contractAddress
      );
    } catch (e) {
      console.error(e);
      throw e;
    }
  });

  describe("testing Mint entrypoint", () => {
    it("mint by send tezos to contract", async () => {
      const bobsTezosBalance = await bobsTezos.rpc.getBalance(accounts.bob.pkh);
      const op = await bobsTezos.wallet
        .transfer({
          to: wTEZuser.contract.address,
          amount: 1,
        })
        .send();
      await confirmOperation(bobsTezos, op.opHash);
      await wTEZuser.updateStorage();
      const bobswTEZbalance = await wTEZuser.storage.ledger.get(
        accounts.bob.pkh
      );
      expect(
        bobsTezosBalance
          .minus(await bobsTezos.rpc.getBalance(accounts.bob.pkh))
          .toNumber()
      ).toBeGreaterThanOrEqual(1000000);
      expect(bobswTEZbalance.toString()).toBe("1000000");
    });

    it("mint by call EP to contract", async function () {
      const bobsTezosBalance = await bobsTezos.rpc.getBalance(accounts.bob.pkh);
      const bobswTEZbalance = await wTEZuser.storage.ledger.get(
        accounts.bob.pkh
      );
      await wTEZuser.mint(1000000, accounts.bob.pkh);
      await wTEZuser.updateStorage();
      const bobswTEZbalance_new = await wTEZuser.storage.ledger.get(
        accounts.bob.pkh
      );
      expect(
        bobsTezosBalance
          .minus(await bobsTezos.rpc.getBalance(accounts.bob.pkh))
          .toNumber()
      ).toBeGreaterThanOrEqual(1000000);
      expect(
        new BigNumber(bobswTEZbalance_new).minus(bobswTEZbalance).toNumber()
      ).toBe(1000000);
    });
  });

  describe("testing Burn entrypoint", () => {
    it("burn and get back tezos by call EP to contract", async function () {
      const bobsTezosBalance = await bobsTezos.rpc.getBalance(accounts.bob.pkh);
      await wTEZuser.updateStorage();
      const bobswTEZbalance = await wTEZuser.storage.ledger.get(
        accounts.bob.pkh
      );
      await wTEZuser.burn(accounts.bob.pkh, 1000000, accounts.bob.pkh);
      await wTEZuser.updateStorage();
      const bobswTEZbalance_new = await wTEZuser.storage.ledger.get(
        accounts.bob.pkh
      );
      expect(
        (await bobsTezos.rpc.getBalance(accounts.bob.pkh))
          .minus(bobsTezosBalance)
          .toNumber()
      ).toBeLessThanOrEqual(1000000);
      expect(
        (await bobsTezos.rpc.getBalance(accounts.bob.pkh))
          .minus(bobsTezosBalance)
          .toNumber()
      ).toBeGreaterThanOrEqual(999000);
      expect(
        new BigNumber(bobswTEZbalance).minus(bobswTEZbalance_new).toNumber()
      ).toBe(1000000);
    });
  });

  describe("testing set_delegate entrypoint", () => {
    it("set_delegate call EP to contract", async function () {
      await wTEZ.updateStorage();
      expect(wTEZ.storage.current_delegate).not.toBe(accounts.alice.pkh);
      await wTEZ.set_delegate(accounts.alice.pkh);
      await wTEZ.updateStorage();
      expect(wTEZ.storage.current_delegate).toStrictEqual(accounts.alice.pkh);
    });
  });

  describe("testing Token endpoints", () => {
    const amount = new BigNumber("100000");

    describe("test transfer from self", () => {
      it(
        "should fail if low balance",
        async () =>
          await failCase(
            "bob",
            async () =>
              await wTEZuser.transfer(
                accounts.bob.pkh,
                accounts.alice.pkh,
                amount.multipliedBy(1000),
                0
              ),
            "FA2_INSUFFICIENT_BALANCE"
          ),
        10000
      );

      it("should send from self", async () => {
        await wTEZuser.updateStorage();
        const bobswTEZbalance = await wTEZuser.storage.ledger.get(
          accounts.bob.pkh
        );
        await wTEZuser.transfer(
          accounts.bob.pkh,
          accounts.alice.pkh,
          amount,
          0
        );
        await wTEZuser.updateStorage();
        const aliceswTEZbalance = await wTEZuser.storage.ledger.get(
          accounts.alice.pkh
        );
        const bobswTEZbalance_new = await wTEZuser.storage.ledger.get(
          accounts.bob.pkh
        );
        expect(
          new BigNumber(bobswTEZbalance).minus(bobswTEZbalance_new)
        ).toStrictEqual(amount);
        expect(new BigNumber(aliceswTEZbalance)).toStrictEqual(amount);
      }, 20000);
    });

    describe("test approve", () => {
      it(
        "should fail send if not approved",
        async () =>
          await failCase(
            "bob",
            async () =>
              await wTEZuser.transfer(
                accounts.alice.pkh,
                accounts.bob.pkh,
                amount,
                0
              ),
            "FA2_NOT_OPERATOR"
          ),
        10000
      );

      it(
        "should update operator",
        async () => await wTEZ.approve(accounts.bob.pkh, amount),
        20000
      );

      it("should send as operator", async () => {
        await wTEZuser.updateStorage();
        const aliceswTEZbalance = await wTEZuser.storage.ledger.get(
          accounts.alice.pkh
        );
        await wTEZuser.transfer(
          accounts.alice.pkh,
          accounts.bob.pkh,
          amount,
          0
        );
        await wTEZuser.updateStorage();
        const aliceswTEZbalance_new = await wTEZuser.storage.ledger.get(
          accounts.alice.pkh
        );
        const bobswTEZbalance = await wTEZuser.storage.ledger.get(
          accounts.bob.pkh
        );
        expect(
          new BigNumber(aliceswTEZbalance).minus(aliceswTEZbalance_new)
        ).toStrictEqual(amount);
        expect(new BigNumber(bobswTEZbalance).toNumber()).toBe(1000000);
      }, 20000);
    });
  });

  describe("token views", () => {
    it("should return balance of account", async () =>
      await wTEZ.contract.views
        .balance_of([
          {
            owner: accounts.alice.pkh,
            token_id: 0,
          },
          {
            owner: accounts.bob.pkh,
            token_id: 0,
          },
        ])
        .read()
        .then((balances) => {
          const aliceBalance = balances.find(
            (b) => b.request.owner === accounts.alice.pkh
          );
          const bobBalance = balances.find(
            (b) => b.request.owner === accounts.bob.pkh
          );
          expect(aliceBalance.balance.toNumber()).toBe(0);
          expect(bobBalance.balance.toNumber()).toBe(1000000);
        }));
  });
});
