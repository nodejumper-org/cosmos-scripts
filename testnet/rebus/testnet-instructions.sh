# Create wallet
rebusd keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: rebus1s43kw25xan605mc4kums09z7u9aw6srv2d0rxq
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Wait util the node is synced, should return FALSE
rebusd status 2>&1 | jq .SyncInfo.catching_up

# Get some tokens in discord

# Verify the balance
rebusd q bank balances $(rebusd keys show wallet -a)

## Console output
#  balances:
#  - amount: "1000000"
#    denom: arebus

# Create validator
anoned tx staking create-validator \
--amount=900000uan1 \
--pubkey=$(rebusd tendermint show-validator) \
--moniker=<YOUR_VALIDATOR_MONIKER> \
--chain-id=anone-testnet-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=20000uan1 \
--from=wallet \
-y

# Make sure you see the validator details
rebusd q staking validator $(rebusd keys show wallet --bech val -a)
