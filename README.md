# Wrapped Tezos in FA2 token

This repository contains contract of FA2 token that can be used for wrapping native Tezos coin (`$XTZ` or `$TEZ`) into FA2 token.

## How to use this contract

Contract implements FA2 interface token with some custom logic. Contract contains single-asset logic for wrapping native Tezos, delegating locked Tezos to bakers (as admin), transfer token and update operators. Token is designed for free minting and burning wrapped tokens.

> All baking rewards for locked and delegated Tezos goes to admin

### FA2 interface

Contract has all required FA2 entrypoints such as `transfer`, `update_operators` and `balance_of` callback view.

### Get wrapped token

If `Alice` wants to wrap her `$XTZ` into `$wXTZ`, she should call `Mint` entrypoint to mint tokens for some receiver. `$XTZ` sent to contract will be locked inside contract untill call `Burn`.

### Get Tezos back

When `Alice` owns `$wXTZ` and want to get back her `$XTZ`s, she should call `Burn` entrypoint. This method sends `amount`of `$XTZ` from contract to the `receiver` passed inside call params.
Also, if `Bob` is `operator` of `Alice`s `$wXTZ`s, he could call `Burn` with `from_` param as `Alice` address and burn her tokens.


## Requirements

- Installed NodeJS (tested with NodeJS v16+)
- Installed Yarn

- Installed node modules with:

```shell
yarn install
```

## Quick Start tests

``` shell
yarn start-sandbox

#> wait for about 10 seconds

yarn test

#> executing tests

yarn stop-sandbox
```

## Compile contract

```shell
yarn compile -c fa2
```

## Deploy contract

```shell
yarn migrate
# Execute yarn migrate -h for more migrate params.
```
