# Create wallet
palomad keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: paloma1lfpde6scf7ulzvuq2suavav6cpmpy0rzxne0pw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.paloma/config/priv_validator_key.json

# Wait util the node is synced, should return FALSE
palomad status 2>&1 | jq .SyncInfo.catching_up

# Go to https://faucet.palomaswap.com and paste your wallet address

# Verify the balance
palomad q bank balances $(palomad keys show wallet -a)

## Console output
#  balances:
#  - amount: "10000000"
#    denom: ugrain

# Create validator
palomad tx staking create-validator \
--amount=9000000ugrain \
--pubkey=$(palomad tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=paloma-testnet-12 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000ugrain \
--from=wallet \
-y

# Make sure you see the validator details
palomad q staking validator $(palomad keys show wallet --bech val -a)
