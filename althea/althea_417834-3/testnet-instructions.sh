# create wallet
althea keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: althea1u8952g337qtgkszzmz3vr5ykkyf3gddx085jg2
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.althea/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
althea status 2>&1 | jq .SyncInfo.catching_up

# Request tokens in discord

# verify the balance
althea q bank balances $(althea keys show wallet -a)

## console output:
#  balances:
#  - amount: "10000000000000000000"
#    denom: ualthea

# create validator
althea tx staking create-validator \
--amount=9000000000000000000ualthea \
--pubkey=$(althea tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=althea_417834-3 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000ualthea \
--from=wallet \
-y

# make sure you see the validator details
althea q staking validator $(althea keys show wallet --bech val -a)
