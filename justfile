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

###

# run-cl remote_builder_opt="":
#   ./bin/lighthouse \
#   --datadir {{CL_DATA_DIR}} \
#   --testnet-dir {{CONFIG_DATA}}/custom_config_data \
#   bn \
#   --disable-enr-auto-update \
#   --enr-udp-port=9000 \
#   --discovery-port=9000 \
#   --port 9000
#   --http --http-address 0.0.0.0 --http-port 5052 \
#   --http-allow-sync-stalled \
#   --jwt-secrets {{CONFIG_DATA}}/cl/jwtsecret \
#   --execution-endpoint http://localhost:8551 \
#   --disable-upnp \
#   {{remote_builder_opt}}

# run-cl-with-remote-builder: (run-cl "--builder http://localhost:18550")

run-validator remote_builder_opt="":
  ./bin/lighthouse \
  --testnet-dir {{CONFIG_DATA}}/custom_config_data \
  vc \
  --init-slashing-protection \
  --validators-dir {{KEYS_DIR}}/keys \
  --secrets-dir {{KEYS_DIR}}/secrets \
  --http --http-port 5062 \
  --suggested-fee-recipient 0xf97e180c050e5Ab072211Ad2C213Eb5AEE4DF134 \
  {{remote_builder_opt}}

run-cl-with-test-builder:
  ./bin/lighthouse \
  --datadir {{CL_DATA_DIR}}/some-cl \
  --testnet-dir {{CONFIG_DATA}}/custom_config_data \
  bn \
  --enable-private-discovery \
  --enr-address 127.0.0.1 \
  --enr-udp-port 9000 \
  --enr-tcp-port 9000 \
  --port 9000 \
  --disable-packet-filter \
  --disable-enr-auto-update \
  --http --http-address 0.0.0.0 --http-port 5052 \
  --http-allow-sync-stalled \
  --jwt-secrets {{CONFIG_DATA}}/cl/jwtsecret \
  --execution-endpoint http://localhost:8553 \
  --disable-upnp \
  --builder http://localhost:18550 \
  --builder-fallback-epochs-since-finalization 9999 \
  --builder-fallback-skips 1000000 \
  --builder-fallback-skips-per-epoch 1000 \
  # --target-peers 1 \


run-validator-with-remote-builder: (run-validator "--builder-proposals")

init-geth:
  ./bin/geth --datadir {{EL_DATA_DIR}}/some-el init {{CONFIG_DATA}}/custom_config_data/genesis.json

run-el:
  ./bin/geth \
  --datadir {{EL_DATA_DIR}}/some-el \
  --networkid {{CHAINID}} \
  --http --http.api "admin,engine,net,eth" \
  --http.port 8545 \
  --http.addr 0.0.0.0 \
  --http.corsdomain "*" \
  --authrpc.port 8553 \
  --authrpc.addr 0.0.0.0 \
  --authrpc.vhosts "*" \
  --authrpc.jwtsecret {{CONFIG_DATA}}/el/jwtsecret \
  --syncmode full \
  --nodekeyhex '4ba16a4dc6fa629c032b5ff18caff254138143fc16b4ae4691c655881268f13c'

run-builder-el:
  ./bin/geth \
  --datadir {{EL_DATA_DIR}}/builder \
  --networkid {{CHAINID}} \
  --port 30304 \
  --http --http.api "admin,engine,net,eth" \
  --http.port 8546 \
  --http.addr 0.0.0.0 \
  --http.corsdomain "*" \
  --authrpc.port 8552 \
  --authrpc.addr 0.0.0.0 \
  --authrpc.vhosts "*" \
  --authrpc.jwtsecret {{CONFIG_DATA}}/el/jwtsecret \
  --syncmode full \
  --nodiscover \
  # --bootnodes 'enode://840bd462c2dcbd393eecfdc547363dd2d24739bc5a16cacb590fde190fe00d3a6a976b76430cc161ea93abe5ed9e54324445d78e5e3bb0ebec73558e2c6cbe0d@127.0.0.1:30303' \

init-geth-builder:
  ./bin/geth --datadir {{EL_DATA_DIR}}/builder init {{CONFIG_DATA}}/custom_config_data/genesis.json

run-builder-cl:
  ./bin/lighthouse \
  --datadir {{CL_DATA_DIR}}/builder \
  --testnet-dir {{CONFIG_DATA}}/custom_config_data \
  bn \
  --enable-private-discovery \
  --enr-address 127.0.0.1 \
  --enr-udp-port 9001 \
  --enr-tcp-port 9001 \
  --port 9001 \
  --disable-packet-filter \
  --disable-enr-auto-update \
  --http --http-address 0.0.0.0 --http-port 5053 \
  --http-allow-sync-stalled \
  --jwt-secrets {{CONFIG_DATA}}/cl/jwtsecret \
  --execution-endpoint http://localhost:8551 \
  --disable-upnp \
  --boot-nodes "enr:-Ly4QL6ptJ2eiky4s7ONOL_xrxeTo9YPqd_x1dgBSxRw88M1UcV8V-qNI6FqhGqlRUSdYpM6KNxJPLKpExDqwiCgqRJFh2F0dG5ldHOI__________-EZXRoMpD8UCF9MAAAQP__________gmlkgnY0gmlwhH8AAAGJc2VjcDI1NmsxoQMrn0mvG9hnyObWytNAhgX8jqjG6mgjH-DIGG4PspEStIhzeW5jbmV0cw-DdGNwgiMog3VkcIIjKA"
  # --target-peers 1 \
