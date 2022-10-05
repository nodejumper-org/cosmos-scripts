# Create wallet
empowerd keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: empower1gved6qjsy8rxf2qxqqtk6uxnalhtm2use3hmnl
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Wait util the node is synced, should return FALSE
empowerd status 2>&1 | jq .SyncInfo.catching_up

# Go to discord channel #faucet and paste
$request <YOUR_WALLET_ADDRESS> altruistic-1

# Verify the balance
empowerd q bank balances $(empowerd keys show wallet -a)

## Console output
#  balances:
#  - amount: "10000000"
#    denom: umpwr

# Create validator
empowerd tx staking create-validator \
--amount=9000000umpwr \
--pubkey=$(empowerd tendermint show-validator) \
--moniker=<YOUR_VALIDATOR_MONIKER> \
--chain-id=altruistic-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--gas-prices=0.1umpwr \
--gas-adjustment=1.5 \
--gas=auto \
--from=wallet \
-y

# Make sure you see the validator details
empowerd q staking validator $(empowerd keys show wallet --bech val -a)