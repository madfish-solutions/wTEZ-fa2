/* eslint-disable jest/prefer-expect-assertions */
import { Tezos, signerAlice, signerBob, accounts } from "./utils/cli";
import config from "../config";
import exampleCode from "../build/fa2.json";
import { confirmOperation } from "../utils/confirmation";
import { SingleTokenFA2 } from "../API/tokenFA2";
import testStorage from "./storage/storage";
import { MichelsonMap, TezosToolkit } from "@taquito/taquito";
import BigNumber from "bignumber.js";
import { BytesString, failCase } from "../utils/helpers";
import { InMemorySigner } from "@taquito/signer";

describe("wTEZ FA2 single-asset tests", () => {
  let wTEZ: SingleTokenFA2;
  let wTEZcandidate: SingleTokenFA2;
  let wTEZuser: SingleTokenFA2;
  const bobsTezos = new TezosToolkit(Tezos.rpc);
  const evesTezos = new TezosToolkit(Tezos.rpc);

  beforeAll(async () => {
    try {
      Tezos.setSignerProvider(signerAlice);
      bobsTezos.setSignerProvider(signerBob);
      evesTezos.setSignerProvider(new InMemorySigner(accounts.eve.sk));

      const deployedContract = await Tezos.contract.originate({
        storage: testStorage,
        code: exampleCode.michelson,
      });
      await confirmOperation(Tezos, deployedContract.hash);
      wTEZ = await SingleTokenFA2.init(Tezos, deployedContract.contractAddress);
      wTEZcandidate = await SingleTokenFA2.init(
        evesTezos,
        deployedContract.contractAddress
      );
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
    it("mint by call EP to contract", async function () {
      const bobsTezosBalance = await bobsTezos.rpc.getBalance(accounts.bob.pkh);
      await wTEZuser.mint(2000000, accounts.bob.pkh);
      await wTEZuser.updateStorage();
      const bobswTEZbalance = await wTEZuser.storage.ledger.get(
        accounts.bob.pkh
      );
      expect(
        bobsTezosBalance
          .minus(await bobsTezos.rpc.getBalance(accounts.bob.pkh))
          .toNumber()
      ).toBeGreaterThanOrEqual(2000000);
      expect(new BigNumber(bobswTEZbalance).toNumber()).toBe(2000000);
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
    it("set_delegate call EP fails if not admin", async () =>
      await failCase(
        "bob",
        async () => await wTEZuser.set_delegate(accounts.bob.pkh),
        "FA2_NOT_ADMIN"
      ));

    it("set_delegate call EP to contract", async function () {
      await wTEZ.updateStorage();
      expect(wTEZ.storage.current_delegate).not.toBe(accounts.alice.pkh);
      await wTEZ.set_delegate(accounts.alice.pkh);
      await wTEZ.updateStorage();
      expect(wTEZ.storage.current_delegate).toStrictEqual(accounts.alice.pkh);
    });
  });

  describe("testing get rewards", () => {
    it("send tezos to contract", async () => {
      await wTEZuser.updateStorage();
      const contractTezosBalance = await bobsTezos.rpc.getBalance(
        wTEZuser.contract.address
      );
      const contractTS = await wTEZuser.storage.token_info.get(0);
      expect(new BigNumber(contractTezosBalance).toNumber()).toStrictEqual(
        new BigNumber(contractTS).toNumber()
      );
      const op = await bobsTezos.wallet
        .transfer({
          to: wTEZuser.contract.address,
          amount: 1,
        })
        .send();
      await confirmOperation(bobsTezos, op.opHash);
      await wTEZuser.updateStorage();
      const contractTezosBalanceAfter = await bobsTezos.rpc.getBalance(
        wTEZuser.contract.address
      );
      const contractTSAfter = await wTEZuser.storage.token_info.get(0);
      expect(new BigNumber(contractTS).toNumber()).toStrictEqual(
        new BigNumber(contractTSAfter).toNumber()
      );
      expect(
        new BigNumber(contractTezosBalanceAfter)
          .minus(contractTezosBalance)
          .toNumber()
      ).toStrictEqual(new BigNumber(1).shiftedBy(6).toNumber());
    });

    it("claim_baking_rewards call EP fails if not admin or candidate", async () =>
      await failCase(
        "eve",
        async () => {
          await wTEZuser.updateStorage();
          const contractTezosBalance = await Tezos.rpc.getBalance(
            wTEZ.contract.address
          );
          const contractTS = await wTEZ.storage.token_info.get(0);
          expect(
            new BigNumber(contractTezosBalance).toNumber()
          ).toBeGreaterThan(new BigNumber(contractTS).toNumber());
          await wTEZuser.claim_baking_rewards(accounts.eve.pkh);
        },
        "FA2_NOT_ADMIN"
      ));

    it("admin gets the rewards", async () => {
      await wTEZ.updateStorage();
      const eveTezosBalance = await Tezos.rpc.getBalance(accounts.eve.pkh);
      const contractTezosBalance = await Tezos.rpc.getBalance(
        wTEZ.contract.address
      );
      const contractTS = await wTEZ.storage.token_info.get(0);
      expect(new BigNumber(contractTezosBalance).toNumber()).toBeGreaterThan(
        new BigNumber(contractTS).toNumber()
      );
      await wTEZ.claim_baking_rewards(accounts.eve.pkh);
      await wTEZ.updateStorage();
      const contractTezosBalanceAfter = await Tezos.rpc.getBalance(
        wTEZ.contract.address
      );
      const contractTSAfter = await wTEZ.storage.token_info.get(0);
      const eveTezosBalanceAfter = await Tezos.rpc.getBalance(accounts.eve.pkh);
      expect(new BigNumber(contractTezosBalanceAfter).toNumber()).toStrictEqual(
        new BigNumber(contractTSAfter).toNumber()
      );
      expect(
        new BigNumber(eveTezosBalanceAfter).minus(eveTezosBalance).toNumber()
      ).toStrictEqual(
        new BigNumber(contractTezosBalance).minus(contractTS).toNumber()
      );
    });
  });

  describe("testing change admin", () => {
    it("set_admin call EP fails if not admin", async () =>
      await failCase(
        "bob",
        async () => await wTEZuser.set_admin(accounts.bob.pkh),
        "FA2_NOT_ADMIN"
      ));

    it("set_admin call EP to contract", async () => {
      await wTEZ.updateStorage();
      expect(wTEZ.storage.admin).not.toBe(accounts.eve.pkh);
      expect(wTEZ.storage.pending_admin).not.toBe(accounts.eve.pkh);
      await wTEZ.set_admin(accounts.eve.pkh);
      await wTEZ.updateStorage();
      expect(wTEZ.storage.admin).not.toBe(accounts.eve.pkh);
      expect(wTEZ.storage.pending_admin).toBe(accounts.eve.pkh);
    });

    it("approve_admin call EP fails if not admin or candidate", async () =>
      await failCase(
        "eve",
        async () => {
          await wTEZuser.updateStorage();
          expect(wTEZuser.storage.admin).not.toBe(accounts.bob.pkh);
          expect(wTEZuser.storage.pending_admin).not.toBe(accounts.bob.pkh);
          await wTEZuser.approve_admin();
        },
        "FA2_NOT_ADMIN"
      ));

    it("approve_admin call EP to contract", async () => {
      await wTEZcandidate.updateStorage();
      expect(wTEZcandidate.storage.admin).not.toBe(accounts.eve.pkh);
      expect(wTEZcandidate.storage.pending_admin).toBe(accounts.eve.pkh);
      await wTEZcandidate.approve_admin();
      await wTEZcandidate.updateStorage();
      expect(wTEZcandidate.storage.admin).toBe(accounts.eve.pkh);
      expect(wTEZcandidate.storage.pending_admin).toBeNull();
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
