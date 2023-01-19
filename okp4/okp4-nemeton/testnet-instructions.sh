# create wallet
okp4d keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: okp410ec4zues3x4xaz89dhv5h4fkdz4cukylxzxt8y
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.okp4d/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
okp4d status 2>&1 | jq .SyncInfo.catching_up

# Go to https://faucet.okp4.network/ and paste your wallet address

# verify the balance
okp4d q bank balances $(okp4d keys show wallet -a)

## console output:
#  balances:
#  - amount: "1000000"
#    denom: uknow

# create validator
okp4d tx staking create-validator \
--amount=900000uknow \
--pubkey=$(okp4d tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=okp4-nemeton \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000uknow \
--from=wallet \
-y

# make sure you see the validator details
okp4d q staking validator $(okp4d keys show wallet --bech val -a)
