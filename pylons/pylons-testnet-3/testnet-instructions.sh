# create wallet
pylonsd keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: pylons1wpkxhzufzrmz6glt4sjp54k3umgvx5hv3rx6y7
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.pylons/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
pylonsd status 2>&1 | jq .SyncInfo.catching_up

# Ask tokens in discord https://discord.com/invite/pylons

# verify the balance
pylonsd q bank balances $(pylonsd keys show wallet -a)

## console output:
#  balances:
#  - amount: "1000000"
#    denom: ubedrock

# create validator
pylonsd tx staking create-validator \
--amount=900000ubedrock \
--pubkey=$(pylonsd tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=pylons-testnet-3 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=20000ubedrock \
--from=wallet \
-y

# make sure you see the validator details
pylonsd q staking validator $(pylonsd keys show wallet --bech val -a)
