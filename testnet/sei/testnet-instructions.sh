# Create wallet
seid keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: sei1lfpde6scf7ulzvuq2suavav6cpmpy0rzxne0pw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Wait util the node is synced, should return FALSE
seid status 2>&1 | jq .SyncInfo.catching_up

# Go to discord channel #atlantic-1-faucet and paste
!faucet <YOUR_WALLET_ADDRESS>

# Verify the balance
seid q bank balances $(seid keys show wallet -a)

## Console output
#  balances:
#  - amount: "1000000"
#    denom: usei

# Create validator
seid tx staking create-validator \
--amount=1000000usei \
--pubkey=$(seid tendermint show-validator) \
--moniker=<YOUR_MONIKER_NAME> \
--chain-id=atlantic-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--from=wallet \
-y

# Make sure you see the validator details
seid q staking validator $(seid keys show wallet --bech val -a)
