# create wallet
cascadiad keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: cascadia104g6jcsg6fmmvn2a2t0nqg4ex68xgqdt2mpqne
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.cascadiad/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
cascadiad status 2>&1 | jq .SyncInfo.catching_up

# get EVM address of your wallet
cascadiad address-converter $(cascadiad keys show wallet -a)

# go to https://www.cascadia.foundation/faucet and faucet some tokens to the EVM wallet

# verify the balance
cascadiad q bank balances $(cascadiad keys show wallet -a)

## console output:
#  balances:
#  - amount: "2000000000000000000"
#    denom: aCC

# create validator
cascadiad tx staking create-validator \
--amount=1000000000000000000aCC \
--pubkey=$(cascadiad tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=cascadia_6102-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--gas-prices=70000000000000aCC \
--gas-adjustment=1.5 \
--gas=auto \
--from=wallet \
-y

# make sure you see the validator details
cascadiad q staking validator $(cascadiad keys show wallet --bech val -a)
