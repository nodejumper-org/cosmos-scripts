# create wallet
gitopiad keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: gitopia1euljtwl6k9tev2lpg69jh5402ym2vl69jwv9sw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.gitopia/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
gitopiad status 2>&1 | jq .SyncInfo.catching_up

# go to https://gitopia.com/ and faucet some tokens to the wallet above

# verify the balance
gitopiad q bank balances $(gitopiad keys show wallet -a)

## console output:
#  balances:
#  - amount: "10000000"
#    denom: utlore

# create validator
gitopiad tx staking create-validator \
--amount=9000000utlore \
--pubkey=$(gitopiad tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=gitopia-janus-testnet-2 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=20000utlore \
--from=wallet \
-y

# make sure you see the validator details
gitopiad q staking validator $(gitopiad keys show wallet --bech val -a)
