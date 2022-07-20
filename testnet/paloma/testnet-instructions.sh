# Create wallet
$binaryName keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: paloma1lfpde6scf7ulzvuq2suavav6cpmpy0rzxne0pw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Wait util the node is synced, should return FALSE
$binaryName status 2>&1 | jq .SyncInfo.catching_up

# Go to https://faucet.palomaswap.com and paste your wallet address

# Verify the balance
$binaryName q bank balances $($binaryName keys show wallet -a)

## Console output
#  balances:
#  - amount: "10000000"
#    denom: ugrain

# Create validator
$binaryName tx staking create-validator \
--amount=9000000$denomName \
--pubkey=$($binaryName tendermint show-validator) \
--moniker=<YOUR_MONIKER_NAME> \
--chain-id=$chainId \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000$denomName \
--from=wallet \
-y

# Make sure you see the validator details
$binaryName q staking validator $($binaryName keys show wallet --bech val -a)
