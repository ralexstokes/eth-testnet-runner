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

create-config: ensure-dirs
  echo {{NOW}}
  docker run --rm -it -u $UID -v $PWD/{{CONFIG_DATA}}:/data -p 127.0.0.1:8000:8000 \
  -v $PWD/{{CONFIG}}:/config \
  -e GENESIS_TIMESTAMP={{NOW}} \
  ethpandaops/ethereum-genesis-generator:latest all

clean:
  rm -rf {{CONFIG_DATA}}
  rm -rf {{KEYS_DIR}}
  rm -rf {{CL_DATA_DIR}}
  rm -rf {{EL_DATA_DIR}}

generate-keys:
  @ # curl -O https://raw.githubusercontent.com/ethereum/consensus-deployment-ansible/master/example-testnet/generate_keys.sh
  bash src/generate_keys.sh
  rm -rf {{KEYS_DIR}}/nimbus-keys
  rm -rf {{KEYS_DIR}}/lodestar-secrets
  rm -rf {{KEYS_DIR}}/prysm
  rm -rf {{KEYS_DIR}}/teku-keys
  rm -rf {{KEYS_DIR}}/teku-secrets

run-cl:
    ./bin/lighthouse \
    --datadir {{CL_DATA_DIR}} \
    --testnet-dir {{CONFIG_DATA}}/custom_config_data \
    bn \
    --http --http-address 0.0.0.0 --http-port 5052 \
    --http-allow-sync-stalled \
    --jwt-secrets {{CONFIG_DATA}}/cl/jwtsecret \
    --execution-endpoint http://localhost:8551 \
    --disable-discovery \
    --disable-upnp

run-validator:
    ./bin/lighthouse \
    --testnet-dir {{CONFIG_DATA}}/custom_config_data \
    vc \
    --init-slashing-protection \
    --validators-dir {{KEYS_DIR}}/keys \
    --secrets-dir {{KEYS_DIR}}/secrets \
    --http --http-port 5062 \
    --suggested-fee-recipient 0xf97e180c050e5Ab072211Ad2C213Eb5AEE4DF134

init-geth:
    ./bin/geth --datadir {{EL_DATA_DIR}} init {{CONFIG_DATA}}/custom_config_data/genesis.json

run-el:
    ./bin/geth \
    --datadir {{EL_DATA_DIR}} \
    --networkid {{CHAINID}} \
    --http --http.api "admin,engine,net,eth" \
    --http.port 8545 \
    --http.addr 0.0.0.0 \
    --http.corsdomain "*" \
    --authrpc.port 8551 \
    --authrpc.addr 0.0.0.0 \
    --authrpc.vhosts "*" \
    --authrpc.jwtsecret {{CONFIG_DATA}}/el/jwtsecret \
    --syncmode full \
    --nodiscover
