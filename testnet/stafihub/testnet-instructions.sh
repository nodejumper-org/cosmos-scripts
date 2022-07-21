# Create wallet
stafihubd keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: stafi1wpkxhzufzrmz6glt4sjp54k3umgvx5hv3rx6y7
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Wait util the node is synced, should return FALSE
stafihubd status 2>&1 | jq .SyncInfo.catching_up

# Go to discord channel #stafi-hub-faucetw and paste
!faucet send <YOUR_WALLET_ADDRESS>

# Verify the balance
stafihubd q bank balances $(stafihubd keys show wallet -a)

## Console output
#  balances:
#  - amount: "100000000"
#    denom: ufis

# Create validator
stafihubd tx staking create-validator \
--amount=99000000ufis \
--pubkey=$(stafihubd tendermint show-validator) \
--moniker=<YOUR_VALIDATOR_MONIKER> \
--chain-id=stafihub-public-testnet-3 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=20000ufis \
--from=wallet \
-y

# Make sure you see the validator details
stafihubd q staking validator $(stafihubd keys show wallet --bech val -a)
