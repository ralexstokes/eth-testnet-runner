CONFIG := "testnet-config"
CONFIG_DATA := "config-data"
KEYS_DIR := "testnet-keys"
CL_DATA_DIR := "cl-data"
EL_DATA_DIR := "el-data"
NOW := `date +%s`

export VALIDATORS_MNEMONIC_0 := `cat config-data/custom_config_data/mnemonics.yaml| yq -r '.[0].mnemonic'`
CHAINID := `cat config-data/custom_config_data/genesis.json | jq .config.chainId`

copy-config-template:
  git clone https://github.com/ethpandaops/ethereum-genesis-generator
  cp -r ethereum-genesis-generator/config-example {{CONFIG}}
  rm -rf ethereum-genesis-generator

ensure-dirs:
  mkdir -p {{CONFIG_DATA}}

generate-keys:
  source {{CONFIG}}/values.env
  bash src/generate_keys.sh
  rm -rf {{KEYS_DIR}}/nimbus-keys
  rm -rf {{KEYS_DIR}}/lodestar-secrets
  rm -rf {{KEYS_DIR}}/prysm
  rm -rf {{KEYS_DIR}}/teku-keys
  rm -rf {{KEYS_DIR}}/teku-secrets

create-genesis: ensure-dirs
  @ docker pull ethpandaops/ethereum-genesis-generator
  docker run --rm -it -u $UID \
  -v $PWD/{{CONFIG_DATA}}:/data \
  -v $PWD/{{CONFIG}}:/config \
  -e GENESIS_TIMESTAMP={{NOW}} \
  ethpandaops/ethereum-genesis-generator:latest all
  rm -rf {{CONFIG_DATA}}/custom_config_data/{tranches,boot_enr.txt,bootstrap_nodes.txt,deploy_block.txt,deposit_contract*,besu.json,chainspec.json,parsedBeaconState.json}
  just generate-keys

clean:
  rm -rf {{CONFIG_DATA}}
  rm -rf {{KEYS_DIR}}
  rm -rf {{CL_DATA_DIR}}
  rm -rf {{EL_DATA_DIR}}

###

run-cl remote_builder_opt="":
  ./bin/lighthouse \
  --datadir {{CL_DATA_DIR}}/some-cl \
  --testnet-dir {{CONFIG_DATA}}/custom_config_data \
  beacon \
  --enable-private-discovery \
  --enr-address 127.0.0.1 \
  --disable-packet-filter \
  --disable-enr-auto-update \
  --staking --http-address 0.0.0.0 --http-port 5052 \
  --http-allow-sync-stalled \
  --execution-jwt {{CONFIG_DATA}}/jwt/jwtsecret \
  --execution-endpoint http://localhost:8551 \
  --disable-upnp \
  {{remote_builder_opt}} \

run-validator remote_builder_opt="":
  ./bin/lighthouse \
  --testnet-dir {{CONFIG_DATA}}/custom_config_data \
  vc \
  --init-slashing-protection \
  --validators-dir {{KEYS_DIR}}/keys \
  --secrets-dir {{KEYS_DIR}}/secrets \
  --http --http-port 5062 \
  --suggested-fee-recipient "0xf97e180c050e5Ab072211Ad2C213Eb5AEE4DF134" \
  {{remote_builder_opt}}

init-geth:
  ./bin/geth \
  --datadir {{EL_DATA_DIR}}/some-el \
  init {{CONFIG_DATA}}/custom_config_data/genesis.json

run-el:
  ./bin/geth \
  --datadir {{EL_DATA_DIR}}/some-el \
  --networkid {{CHAINID}} \
  --http \
  --syncmode=full \
  --authrpc.jwtsecret {{CONFIG_DATA}}/jwt/jwtsecret
