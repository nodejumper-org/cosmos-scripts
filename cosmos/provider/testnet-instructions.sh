# create wallet
gaiad keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: cosmos102w6jk6jpakck3xknt7g9pr0wr2plhv5yr4whz
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.gaia/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
gaiad status 2>&1 | jq .SyncInfo.catching_up

# Visit faucet.rs-testnet.polypore.xyz to request tokens
https://faucet.rs-testnet.polypore.xyz/request?address=YOUR_WALLET_ADDRESS&chain=provider

# verify the balance
gaiad q bank balances $(gaiad keys show wallet -a)

## console output:
#  balances:
#  - amount: "10000000"
#    denom: uatom

# create validator
gaiad tx staking create-validator \
--amount=9000000uatom \
--pubkey=$(gaiad tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=provider \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000uatom \
--from=wallet \
-y

# make sure you see the validator details
gaiad q staking validator $(gaiad keys show wallet --bech val -a)
