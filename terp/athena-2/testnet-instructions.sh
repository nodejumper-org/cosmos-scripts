# Create wallet
terpd keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: terp1rwyn6w46u3167enhpdceqasg2um8dddtt5ursa
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Wait util the node is synced, should return FALSE
terpd status 2>&1 | jq .SyncInfo.catching_up

# Go to discord server and ask for some tokens for validator creation

# Verify the balance
terpd q bank balances $(terpd keys show wallet -a)

## Console output
#  balances:
#  - amount: "1000000000"
#    denom: uterpx

# Create validator
terpd tx staking create-validator \
--amount=100000000uterpx \
--pubkey=$(terpd tendermint show-validator) \
--moniker=<YOUR_VALIDATOR_MONIKER> \
--chain-id=athena-2 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--from=wallet \
-y

# Make sure you see the validator details
terpd q staking validator $(terpd keys show wallet --bech val -a)
