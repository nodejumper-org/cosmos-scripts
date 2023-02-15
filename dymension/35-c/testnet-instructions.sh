# create wallet
dymd keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: dym1d6z48lnw0g9l8ndumsy9r4cc5xw334mgatm4kx
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE (example)
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.dymension/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
dymd status 2>&1 | jq .SyncInfo.catching_up

# get some tokens - try to ask in discord

# verify the balance
dymd q bank balances $(dymd keys show wallet -a)

## console output:
#  balances:
#  - amount: "2000000"
#    denom: udym

# create validator
dymd tx staking create-validator \
--amount=1000000udym \
--pubkey=$(dymd tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=35-C \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=1000udym \
--from=wallet \
-y

# make sure you see the validator details
dymd q staking validator $(dymd keys show wallet --bech val -a)
