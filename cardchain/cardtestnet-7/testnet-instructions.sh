# create wallet
cardchaind keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: cc1d2gnx8gxf44tkjky7ftwfkg9k0lln56xfaxucp
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.Cardchain/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
cardchaind status 2>&1 | jq .SyncInfo.catching_up

# go to https://crowdcontrol.network/#/about and import your wallet address using seed phase above

# verify the balance
cardchaind q bank balances $(cardchaind keys show wallet -a)

## console output:
#  balances:
#  - amount: "5000000"
#    denom: ubpf

# create validator
cardchaind tx staking create-validator \
--amount=4000000ubpf \
--pubkey=$(cardchaind tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=cardtestnet-7 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--from=wallet \
-y

# make sure you see the validator details
cardchaind q staking validator $(cardchaind keys show wallet --bech val -a)
