# create wallet
marsd keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: mars1lfpde6scf7ulzvuq2suavav6cpmpy0rzxne0pw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE (example)
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.mars/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
marsd status 2>&1 | jq .SyncInfo.catching_up

# go to the website https://faucet.marsprotocol.io, connect the wallet above and do faucet

# verify the balance
marsd q bank balances $(marsd keys show wallet -a)

## console output:
#  balances:
#  - amount: "5000000"
#    denom: umars

# create validator
marsd tx staking create-validator \
--amount=4900000umars \
--pubkey=$(marsd tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=ares-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=10000umars \
--from=wallet \
-y

# make sure you see the validator details
marsd q staking validator $(marsd keys show wallet --bech val -a)
