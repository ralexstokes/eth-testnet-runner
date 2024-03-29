#!/bin/bash

# modified from https://github.com/ethereum/consensus-deployment-ansible/blob/master/example-testnet/generate_keys.sh

source $1

if [ -z "$EL_AND_CL_MNEMONIC" ]; then
  echo "missing mnemonic"
  exit 1
fi

if [ -z "$NUMBER_OF_VALIDATORS" ]; then
  echo "missing number of validators"
  exit 1
fi

function prep_group {
  let group_base=$1
  validators_source_mnemonic="$2"
  let offset=$3
  let keys_to_create=$4
  naming_prefix="$5"
  validators_per_host=$6
  for (( i = 0; i < keys_to_create; i++ )); do
    let node_index=group_base+i
    let offset_i=offset+i
    let validators_source_min=offset_i*validators_per_host
    let validators_source_max=validators_source_min+validators_per_host

    echo "writing keystores to 'config-data/keys'"
    eth2-val-tools keystores \
    --insecure \
    --out-loc="config-data/keys" \
    --source-max="$validators_source_max" \
    --source-min="$validators_source_min" \
    --source-mnemonic="$validators_source_mnemonic"
  done
}

prep_group 1 "$EL_AND_CL_MNEMONIC" 0 1 "example-testnet" $NUMBER_OF_VALIDATORS
