# Create wallet
Cardchain keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: cc1d2gnx8gxf44tkjky7ftwfkg9k0lln56xfaxucp
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Wait util the node is synced, should return FALSE
Cardchain status 2>&1 | jq .SyncInfo.catching_up

# Go to https://dragonapi.space/ and paste your wallet address

# Verify the balance
Cardchain q bank balances $(Cardchain keys show wallet -a)

## Console output
#  balances:
#  - amount: "5000000"
#    denom: ubpf

# Create validator
Cardchain tx staking create-validator \
--amount=5000000ubpf \
--pubkey=$(Cardchain tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=Cardchain \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--from=wallet \
-y

# Make sure you see the validator details
Cardchain q staking validator $(Cardchain keys show wallet --bech val -a)
