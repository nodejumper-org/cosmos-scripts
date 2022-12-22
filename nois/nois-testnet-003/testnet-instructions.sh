# create wallet
noisd keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: nois1lfpde6scf7ulzvuq2suavav6cpmpy0rzxne0pw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE (example)
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.noisd/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
noisd status 2>&1 | jq .SyncInfo.catching_up

# go to discord channel #testnet-faucet and paste
!request YOUR_WALLET_ADDRESS

# verify the balance
noisd q bank balances $(noisd keys show wallet -a)

## console output:
#  balances:
#  - amount: "10000000"
#    denom: unois

# create validator
noisd tx staking create-validator \
--amount=8000000unois \
--pubkey=$(noisd tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=nois-testnet-003 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000unois \
--from=wallet \
-y

# make sure you see the validator details
noisd q staking validator $(noisd keys show wallet --bech val -a)
