# create wallet
defundd keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: defund1r9kmadqs9nsppn4wz5yp4rw8zn9545rc4zwvs7
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.defund/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
defundd status 2>&1 | jq .SyncInfo.catching_up

# go to https://discord.gg/UsER6bWuUq and request tokens in faucet channel

# verify the balance
defundd q bank balances $(defundd keys show wallet -a)

## console output:
#  balances:
#  - amount: "20000000"
#    denom: ufetf

# create validator
defundd tx staking create-validator \
--amount=10000000ufetf \
--pubkey=$(defundd tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=defund-private-3 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000ufetf \
--from=wallet \
-y

# make sure you see the validator details
defundd q staking validator $(defundd keys show wallet --bech val -a)
