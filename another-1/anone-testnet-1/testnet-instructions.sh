# Create wallet
anoned keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: one1wpkxhzufzrmz6glt4sjp54k3umgvx5hv3rx6y7
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.anone/config/priv_validator_key.json

# Wait util the node is synced, should return FALSE
anoned status 2>&1 | jq .SyncInfo.catching_up

# Go to discord channel #faucet-testnet-1 and paste
$request YOUR_WALLET_ADDRESS

# Verify the balance
anoned q bank balances $(anoned keys show wallet -a)

## Console output
#  balances:
#  - amount: "5000000"
#    denom: uan1

# Create validator
anoned tx staking create-validator \
--amount=4500000uan1 \
--pubkey=$(anoned tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=anone-testnet-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=20000uan1 \
--from=wallet \
-y

# Make sure you see the validator details
anoned q staking validator $(anoned keys show wallet --bech val -a)
