# Create wallet
humansd keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: human1lfpde6scf7ulzvuq2suavav6cpmpy0rzxne0pw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE (example)
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.humans/config/priv_validator_key.json

# Wait util the node is synced, should return FALSE
humansd status 2>&1 | jq .SyncInfo.catching_up

# Go to discord https://discord.gg/humansdotai channel #testnet-faucet and paste
$request YOUR_WALLET_ADDRESS

# Verify the balance
humansd q bank balances $(humansd keys show wallet -a)

## Console output
#  balances:
#  - amount: "10000000"
#    denom: uheart

# Create validator
humansd tx staking create-validator \
--amount=9000000uheart \
--pubkey=$(humansd tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=testnet-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=10000uheart \
--from=wallet \
-y

# Make sure you see the validator details
humansd q staking validator $(humansd keys show wallet --bech val -a)
