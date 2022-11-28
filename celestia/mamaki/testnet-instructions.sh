# Create wallet
celestia-appd keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: celestia19kmadqs9nsppn4wz5yp4rw8zn9545rc4zwvs7
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Wait util the node is synced, should return FALSE
celestia-appd status 2>&1 | jq .SyncInfo.catching_up

# Go to https://discord.gg/kUSueaB22b and request tokens in faucet channel

# Verify the balance
celestia-appd q bank balances $(celestia-appd keys show wallet -a)

## Console output
#  balances:
#  - amount: "1000000"
#    denom: utia

# Create validator
celestia-appd tx staking create-validator \
--amount=1000000utia \
--pubkey=$(celestia-appd tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=mamaki \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000unibi \
--from=wallet \
-y

# Make sure you see the validator details
celestia-appd q staking validator $(celestia-appd keys show wallet --bech val -a)
