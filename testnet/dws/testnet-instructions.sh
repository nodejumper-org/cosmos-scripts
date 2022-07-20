# Create wallet
$binaryName keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: deweb1txne45klcm3w98merz25u94d7v9mlev3wngzrz
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Wait util the node is synced, should return FALSE
$binaryName status 2>&1 | jq .SyncInfo.catching_up

# Go to discord channel #faucet and paste
$request <YOUR_WALLET_ADDRESS> menkar

# Verify the balance
$binaryName q bank balances $($binaryName keys show wallet -a)

## Console output
#  balances:
#  - amount: "5000000"
#    denom: udws

# Create validator
$binaryName tx staking create-validator \
--amount=4500000$denomName \
--pubkey=$($binaryName tendermint show-validator) \
--moniker=<YOUR_MONIKER_NAME> \
--chain-id=$chainId \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=20000$denomName \
--from=wallet \
-y

# Make sure you see the validator details
$binaryName q staking validator $($binaryName keys show wallet --bech val -a)
