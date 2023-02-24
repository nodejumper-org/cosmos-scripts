# create wallet
quasard keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: quasar1d6z48lnw0g9l8ndumsy9r4cc5xw334mgatm4kx
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE (example)
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.quasarnode/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
quasard status 2>&1 | jq .SyncInfo.catching_up

# go to discord channel and paste
!faucet QSR YOUR_WALLET_ADDRESS


# verify the balance
quasard q bank balances $(quasard keys show wallet -a)

## console output:
#  balances:
#  - amount: "1000000"
#    denom: uqsr

# create validator
quasard tx staking create-validator \
--amount=1000000uqsr \
--pubkey=$(quasard tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=qsr-questnet-04 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--from=wallet \
-y

# make sure you see the validator details
quasard q staking validator $(quasard keys show wallet --bech val -a)