# create wallet
Cardchaind keys add wallet

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
Cardchaind status 2>&1 | jq .SyncInfo.catching_up

# Go to https://crowdcontrol.network/#/about and import your wallet address using seed phase above

# verify the balance
Cardchaind q bank balances $(Cardchaind keys show wallet -a)

## console output:
#  balances:
#  - amount: "5000000"
#    denom: ubpf

# create validator
Cardchaind tx staking create-validator \
--amount=5000000ubpf \
--pubkey=$(Cardchaind tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=Testnet3 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--from=wallet \
-y

# make sure you see the validator details
Cardchaind q staking validator $(Cardchaind keys show wallet --bech val -a)
