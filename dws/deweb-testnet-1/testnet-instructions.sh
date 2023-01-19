# сreate wallet
dewebd keys add wallet

# сonsole output
#- name: wallet
#  type: local
#  address: deweb1txne45klcm3w98merz25u94d7v9mlev3wngzrz
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.deweb/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
dewebd status 2>&1 | jq .SyncInfo.catching_up

# go to discord channel #faucet and paste
$request YOUR_WALLET_ADDRESS menkar

# verify the balance
dewebd q bank balances $(dewebd keys show wallet -a)

## console output:
#  balances:
#  - amount: "5000000"
#    denom: udws

# create validator
dewebd tx staking create-validator \
--amount=4500000udws \
--pubkey=$(dewebd tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=deweb-testnet-sirius \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=20000udws \
--from=wallet \
-y

# make sure you see the validator details
dewebd q staking validator $(dewebd keys show wallet --bech val -a)
