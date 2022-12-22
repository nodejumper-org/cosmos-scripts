# create wallet
nolusd keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: nolus1y7lfy9909gjfrrudwa3y8z0ndp9xlf0anvrkfw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.nolus/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
nolusd status 2>&1 | jq .SyncInfo.catching_up

# go to discord channel #testnet-faucet and paste
$request YOUR_WALLET_ADDRESS nolus-rila

# verify the balance
nolusd q bank balances $(nolusd keys show wallet -a)

## console output:
#  balances:
#  - amount: "2000000"
#    denom: unls

# create validator
nolusd tx staking create-validator \
--amount=1500000unls \
--pubkey=$(nolusd tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=nolus-rila \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=20000unls \
--from=wallet \
-y

# make sure you see the validator details
nolusd q staking validator $(nolusd keys show wallet --bech val -a)
