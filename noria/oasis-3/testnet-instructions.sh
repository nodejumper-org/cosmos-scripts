# create wallet
noriad keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: noria18mvny5jpve6lmtvykxn7uslnlnwts3y2tx7p6a
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE (example)
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.noria/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
noriad status 2>&1 | jq .SyncInfo.catching_up

# go to discord https://discord.gg/xVMWBreSfN and ask for some tokens

# verify the balance
noriad q bank balances $(noriad keys show wallet -a)

## console output:
#  balances:
#  - amount: "10000000"
#    denom: ucrd

# create validator
noriad tx staking create-validator \
--amount=9000000ucrd \
--pubkey=$(noriad tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=oasis-3 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=10000ucrd \
--from=wallet \
-y

# make sure you see the validator details
noriad q staking validator $(noriad keys show wallet --bech val -a)
