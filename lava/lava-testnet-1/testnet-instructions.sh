# create wallet
lavad keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: lava@1us3tv59r3wz57ydjafkzgpy0pccae2a2e4k5en
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE (example)
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.lava/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
lavad status 2>&1 | jq .SyncInfo.catching_up

# faucet some tokens with the command below or ask in discord, if the command doesn't work
curl -X POST -d '{"address": "YOUR_WALLET_ADDRESS", "coins": ["10000000ulava"]}' https://faucet-api.lavanet.xyz/faucet/

# verify the balance
lavad q bank balances $(lavad keys show wallet -a)

## console output:
#  balances:
#  - amount: "10000000"
#    denom: ulava

# create validator
lavad tx staking create-validator \
--amount=9000000ulava \
--pubkey=$(lavad tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=lava-testnet-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=10000ulava \
--from=wallet \
-y

# make sure you see the validator details
lavad q staking validator $(lavad keys show wallet --bech val -a)
