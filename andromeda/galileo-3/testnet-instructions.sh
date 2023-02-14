# create wallet
andromedad keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: andr1d6z48lnw0g9l8ndumsy9r4cc5xw334mgatm4kx
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE (example)
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.andromedad/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
andromedad status 2>&1 | jq .SyncInfo.catching_up

# faucet some tokens in #faucet-pub discord channel
!request andr1d6z48lnw0g9l8ndumsy9r4cc5xw334mgatm4kx

# verify the balance
andromedad q bank balances $(andromedad keys show wallet -a)

## console output:
#  balances:
#  - amount: "2000000"
#    denom: uandr

# create validator
andromedad tx staking create-validator \
--amount=1000000uandr \
--pubkey=$(andromedad tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=galileo-3 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=10000uandr \
--from=wallet \
-y

# make sure you see the validator details
andromedad q staking validator $(andromedad keys show wallet --bech val -a)
