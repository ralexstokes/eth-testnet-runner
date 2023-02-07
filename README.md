# eth-testnet-runner

Generates config for a local testnet and provides commands to run 1 peer with a small number of validators.

# Notes on creating testnet

Currently only supports `lighthouse` and `geth`.

## Dependencies

Expects `geth`, `ligthhouse` and `eth2-val-tools` in `bin` dir.

## Steps

1. `just create-config`

2. `just generate-keys`

3. `just init-geth`

4. run clients:
- `just run-el`
- `just run-cl`
- `just run-validator`


## Sources

https://github.com/ethpandaops/ethereum-genesis-generator

https://github.com/ethereum/consensus-deployment-ansible
