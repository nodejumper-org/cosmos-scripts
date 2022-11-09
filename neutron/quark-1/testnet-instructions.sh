# Create wallet
neutrond keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: neutron1r9kmadqs9nsppn4wz5yp4rw8zn9545rc4zwvs7
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Wait util the node is synced, should return FALSE
neutrond status 2>&1 | jq .SyncInfo.catching_up

# Go to https://discord.gg/U7c5uaxFSq and request tokens either via faucet or P2P

# Verify the balance
neutrond q bank balances $(neutrond keys show wallet -a)

## Console output
#  balances:
#  - amount: "1000000"
#    denom: untrn

# Create validator
neutrond tx staking create-validator \
--amount=900000untrn \
--pubkey=$(neutrond tendermint show-validator) \
--moniker=<YOUR_VALIDATOR_MONIKER> \
--chain-id=quark-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000untrn \
--from=wallet \
-y

# Make sure you see the validator details
neutrond q staking validator $(neutrond keys show wallet --bech val -a)
